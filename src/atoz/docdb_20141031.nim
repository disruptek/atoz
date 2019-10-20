
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_592959 = ref object of OpenApiRestCall_592348
proc url_PostAddTagsToResource_592961(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_592960(path: JsonNode; query: JsonNode;
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
  var valid_592962 = query.getOrDefault("Action")
  valid_592962 = validateParameter(valid_592962, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592962 != nil:
    section.add "Action", valid_592962
  var valid_592963 = query.getOrDefault("Version")
  valid_592963 = validateParameter(valid_592963, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_592963 != nil:
    section.add "Version", valid_592963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592964 = header.getOrDefault("X-Amz-Signature")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Signature", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Content-Sha256", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Date")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Date", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Credential")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Credential", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Security-Token")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Security-Token", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Algorithm")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Algorithm", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-SignedHeaders", valid_592970
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_592971 = formData.getOrDefault("Tags")
  valid_592971 = validateParameter(valid_592971, JArray, required = true, default = nil)
  if valid_592971 != nil:
    section.add "Tags", valid_592971
  var valid_592972 = formData.getOrDefault("ResourceName")
  valid_592972 = validateParameter(valid_592972, JString, required = true,
                                 default = nil)
  if valid_592972 != nil:
    section.add "ResourceName", valid_592972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592973: Call_PostAddTagsToResource_592959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_592973.validator(path, query, header, formData, body)
  let scheme = call_592973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592973.url(scheme.get, call_592973.host, call_592973.base,
                         call_592973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592973, url, valid)

proc call*(call_592974: Call_PostAddTagsToResource_592959; Tags: JsonNode;
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
  var query_592975 = newJObject()
  var formData_592976 = newJObject()
  add(query_592975, "Action", newJString(Action))
  if Tags != nil:
    formData_592976.add "Tags", Tags
  add(query_592975, "Version", newJString(Version))
  add(formData_592976, "ResourceName", newJString(ResourceName))
  result = call_592974.call(nil, query_592975, nil, formData_592976, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_592959(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_592960, base: "/",
    url: url_PostAddTagsToResource_592961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_592687 = ref object of OpenApiRestCall_592348
proc url_GetAddTagsToResource_592689(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_592688(path: JsonNode; query: JsonNode;
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
  var valid_592801 = query.getOrDefault("Tags")
  valid_592801 = validateParameter(valid_592801, JArray, required = true, default = nil)
  if valid_592801 != nil:
    section.add "Tags", valid_592801
  var valid_592802 = query.getOrDefault("ResourceName")
  valid_592802 = validateParameter(valid_592802, JString, required = true,
                                 default = nil)
  if valid_592802 != nil:
    section.add "ResourceName", valid_592802
  var valid_592816 = query.getOrDefault("Action")
  valid_592816 = validateParameter(valid_592816, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592816 != nil:
    section.add "Action", valid_592816
  var valid_592817 = query.getOrDefault("Version")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_592817 != nil:
    section.add "Version", valid_592817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592818 = header.getOrDefault("X-Amz-Signature")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Signature", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Content-Sha256", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Date")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Date", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Credential")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Credential", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Security-Token")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Security-Token", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Algorithm")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Algorithm", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-SignedHeaders", valid_592824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_GetAddTagsToResource_592687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_GetAddTagsToResource_592687; Tags: JsonNode;
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
  var query_592919 = newJObject()
  if Tags != nil:
    query_592919.add "Tags", Tags
  add(query_592919, "ResourceName", newJString(ResourceName))
  add(query_592919, "Action", newJString(Action))
  add(query_592919, "Version", newJString(Version))
  result = call_592918.call(nil, query_592919, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_592687(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_592688, base: "/",
    url: url_GetAddTagsToResource_592689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_592995 = ref object of OpenApiRestCall_592348
proc url_PostApplyPendingMaintenanceAction_592997(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_592996(path: JsonNode;
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
  var valid_592998 = query.getOrDefault("Action")
  valid_592998 = validateParameter(valid_592998, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_592998 != nil:
    section.add "Action", valid_592998
  var valid_592999 = query.getOrDefault("Version")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_592999 != nil:
    section.add "Version", valid_592999
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593000 = header.getOrDefault("X-Amz-Signature")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Signature", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Content-Sha256", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Date")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Date", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Credential")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Credential", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Security-Token")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Security-Token", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Algorithm")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Algorithm", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-SignedHeaders", valid_593006
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
  var valid_593007 = formData.getOrDefault("ResourceIdentifier")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "ResourceIdentifier", valid_593007
  var valid_593008 = formData.getOrDefault("ApplyAction")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = nil)
  if valid_593008 != nil:
    section.add "ApplyAction", valid_593008
  var valid_593009 = formData.getOrDefault("OptInType")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "OptInType", valid_593009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_PostApplyPendingMaintenanceAction_592995;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_PostApplyPendingMaintenanceAction_592995;
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
  var query_593012 = newJObject()
  var formData_593013 = newJObject()
  add(formData_593013, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_593013, "ApplyAction", newJString(ApplyAction))
  add(query_593012, "Action", newJString(Action))
  add(formData_593013, "OptInType", newJString(OptInType))
  add(query_593012, "Version", newJString(Version))
  result = call_593011.call(nil, query_593012, nil, formData_593013, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_592995(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_592996, base: "/",
    url: url_PostApplyPendingMaintenanceAction_592997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_592977 = ref object of OpenApiRestCall_592348
proc url_GetApplyPendingMaintenanceAction_592979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_592978(path: JsonNode;
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
  var valid_592980 = query.getOrDefault("ResourceIdentifier")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = nil)
  if valid_592980 != nil:
    section.add "ResourceIdentifier", valid_592980
  var valid_592981 = query.getOrDefault("ApplyAction")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "ApplyAction", valid_592981
  var valid_592982 = query.getOrDefault("Action")
  valid_592982 = validateParameter(valid_592982, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_592982 != nil:
    section.add "Action", valid_592982
  var valid_592983 = query.getOrDefault("OptInType")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = nil)
  if valid_592983 != nil:
    section.add "OptInType", valid_592983
  var valid_592984 = query.getOrDefault("Version")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_592984 != nil:
    section.add "Version", valid_592984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592985 = header.getOrDefault("X-Amz-Signature")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Signature", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Content-Sha256", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Date")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Date", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Credential")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Credential", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Security-Token")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Security-Token", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Algorithm")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Algorithm", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-SignedHeaders", valid_592991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592992: Call_GetApplyPendingMaintenanceAction_592977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_592992.validator(path, query, header, formData, body)
  let scheme = call_592992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592992.url(scheme.get, call_592992.host, call_592992.base,
                         call_592992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592992, url, valid)

proc call*(call_592993: Call_GetApplyPendingMaintenanceAction_592977;
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
  var query_592994 = newJObject()
  add(query_592994, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_592994, "ApplyAction", newJString(ApplyAction))
  add(query_592994, "Action", newJString(Action))
  add(query_592994, "OptInType", newJString(OptInType))
  add(query_592994, "Version", newJString(Version))
  result = call_592993.call(nil, query_592994, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_592977(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_592978, base: "/",
    url: url_GetApplyPendingMaintenanceAction_592979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_593033 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBClusterParameterGroup_593035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_593034(path: JsonNode;
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
  var valid_593036 = query.getOrDefault("Action")
  valid_593036 = validateParameter(valid_593036, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_593036 != nil:
    section.add "Action", valid_593036
  var valid_593037 = query.getOrDefault("Version")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593037 != nil:
    section.add "Version", valid_593037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Date")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Date", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Credential")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Credential", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Security-Token")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Security-Token", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Algorithm")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Algorithm", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-SignedHeaders", valid_593044
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
  var valid_593045 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_593045 = validateParameter(valid_593045, JString, required = true,
                                 default = nil)
  if valid_593045 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_593045
  var valid_593046 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_593046 = validateParameter(valid_593046, JString, required = true,
                                 default = nil)
  if valid_593046 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_593046
  var valid_593047 = formData.getOrDefault("Tags")
  valid_593047 = validateParameter(valid_593047, JArray, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "Tags", valid_593047
  var valid_593048 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_593048 = validateParameter(valid_593048, JString, required = true,
                                 default = nil)
  if valid_593048 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_593048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593049: Call_PostCopyDBClusterParameterGroup_593033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_593049.validator(path, query, header, formData, body)
  let scheme = call_593049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593049.url(scheme.get, call_593049.host, call_593049.base,
                         call_593049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593049, url, valid)

proc call*(call_593050: Call_PostCopyDBClusterParameterGroup_593033;
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
  var query_593051 = newJObject()
  var formData_593052 = newJObject()
  add(formData_593052, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(formData_593052, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_593051, "Action", newJString(Action))
  if Tags != nil:
    formData_593052.add "Tags", Tags
  add(query_593051, "Version", newJString(Version))
  add(formData_593052, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  result = call_593050.call(nil, query_593051, nil, formData_593052, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_593033(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_593034, base: "/",
    url: url_PostCopyDBClusterParameterGroup_593035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_593014 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBClusterParameterGroup_593016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_593015(path: JsonNode;
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
  var valid_593017 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = nil)
  if valid_593017 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_593017
  var valid_593018 = query.getOrDefault("Tags")
  valid_593018 = validateParameter(valid_593018, JArray, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "Tags", valid_593018
  var valid_593019 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_593019 = validateParameter(valid_593019, JString, required = true,
                                 default = nil)
  if valid_593019 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_593019
  var valid_593020 = query.getOrDefault("Action")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_593020 != nil:
    section.add "Action", valid_593020
  var valid_593021 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_593021 = validateParameter(valid_593021, JString, required = true,
                                 default = nil)
  if valid_593021 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_593021
  var valid_593022 = query.getOrDefault("Version")
  valid_593022 = validateParameter(valid_593022, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593022 != nil:
    section.add "Version", valid_593022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593023 = header.getOrDefault("X-Amz-Signature")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Signature", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Content-Sha256", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Date")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Date", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Credential")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Credential", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Security-Token")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Security-Token", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Algorithm")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Algorithm", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-SignedHeaders", valid_593029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593030: Call_GetCopyDBClusterParameterGroup_593014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_593030.validator(path, query, header, formData, body)
  let scheme = call_593030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593030.url(scheme.get, call_593030.host, call_593030.base,
                         call_593030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593030, url, valid)

proc call*(call_593031: Call_GetCopyDBClusterParameterGroup_593014;
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
  var query_593032 = newJObject()
  add(query_593032, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    query_593032.add "Tags", Tags
  add(query_593032, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_593032, "Action", newJString(Action))
  add(query_593032, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_593032, "Version", newJString(Version))
  result = call_593031.call(nil, query_593032, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_593014(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_593015, base: "/",
    url: url_GetCopyDBClusterParameterGroup_593016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_593074 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBClusterSnapshot_593076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterSnapshot_593075(path: JsonNode; query: JsonNode;
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
  var valid_593077 = query.getOrDefault("Action")
  valid_593077 = validateParameter(valid_593077, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_593077 != nil:
    section.add "Action", valid_593077
  var valid_593078 = query.getOrDefault("Version")
  valid_593078 = validateParameter(valid_593078, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593078 != nil:
    section.add "Version", valid_593078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593079 = header.getOrDefault("X-Amz-Signature")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Signature", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Content-Sha256", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Date")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Date", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Credential")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Credential", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Security-Token")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Security-Token", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Algorithm")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Algorithm", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-SignedHeaders", valid_593085
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
  var valid_593086 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_593086 = validateParameter(valid_593086, JString, required = true,
                                 default = nil)
  if valid_593086 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_593086
  var valid_593087 = formData.getOrDefault("KmsKeyId")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "KmsKeyId", valid_593087
  var valid_593088 = formData.getOrDefault("PreSignedUrl")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "PreSignedUrl", valid_593088
  var valid_593089 = formData.getOrDefault("CopyTags")
  valid_593089 = validateParameter(valid_593089, JBool, required = false, default = nil)
  if valid_593089 != nil:
    section.add "CopyTags", valid_593089
  var valid_593090 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_593090 = validateParameter(valid_593090, JString, required = true,
                                 default = nil)
  if valid_593090 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_593090
  var valid_593091 = formData.getOrDefault("Tags")
  valid_593091 = validateParameter(valid_593091, JArray, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "Tags", valid_593091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593092: Call_PostCopyDBClusterSnapshot_593074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_593092.validator(path, query, header, formData, body)
  let scheme = call_593092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593092.url(scheme.get, call_593092.host, call_593092.base,
                         call_593092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593092, url, valid)

proc call*(call_593093: Call_PostCopyDBClusterSnapshot_593074;
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
  var query_593094 = newJObject()
  var formData_593095 = newJObject()
  add(formData_593095, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_593095, "KmsKeyId", newJString(KmsKeyId))
  add(formData_593095, "PreSignedUrl", newJString(PreSignedUrl))
  add(formData_593095, "CopyTags", newJBool(CopyTags))
  add(formData_593095, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_593094, "Action", newJString(Action))
  if Tags != nil:
    formData_593095.add "Tags", Tags
  add(query_593094, "Version", newJString(Version))
  result = call_593093.call(nil, query_593094, nil, formData_593095, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_593074(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_593075, base: "/",
    url: url_PostCopyDBClusterSnapshot_593076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_593053 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBClusterSnapshot_593055(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterSnapshot_593054(path: JsonNode; query: JsonNode;
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
  var valid_593056 = query.getOrDefault("Tags")
  valid_593056 = validateParameter(valid_593056, JArray, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "Tags", valid_593056
  var valid_593057 = query.getOrDefault("KmsKeyId")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "KmsKeyId", valid_593057
  var valid_593058 = query.getOrDefault("PreSignedUrl")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "PreSignedUrl", valid_593058
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_593059 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_593059
  var valid_593060 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_593060 = validateParameter(valid_593060, JString, required = true,
                                 default = nil)
  if valid_593060 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_593060
  var valid_593061 = query.getOrDefault("Action")
  valid_593061 = validateParameter(valid_593061, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_593061 != nil:
    section.add "Action", valid_593061
  var valid_593062 = query.getOrDefault("CopyTags")
  valid_593062 = validateParameter(valid_593062, JBool, required = false, default = nil)
  if valid_593062 != nil:
    section.add "CopyTags", valid_593062
  var valid_593063 = query.getOrDefault("Version")
  valid_593063 = validateParameter(valid_593063, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593063 != nil:
    section.add "Version", valid_593063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593064 = header.getOrDefault("X-Amz-Signature")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Signature", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Content-Sha256", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Date")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Date", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Credential")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Credential", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Security-Token")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Security-Token", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Algorithm")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Algorithm", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-SignedHeaders", valid_593070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593071: Call_GetCopyDBClusterSnapshot_593053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_593071.validator(path, query, header, formData, body)
  let scheme = call_593071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593071.url(scheme.get, call_593071.host, call_593071.base,
                         call_593071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593071, url, valid)

proc call*(call_593072: Call_GetCopyDBClusterSnapshot_593053;
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
  var query_593073 = newJObject()
  if Tags != nil:
    query_593073.add "Tags", Tags
  add(query_593073, "KmsKeyId", newJString(KmsKeyId))
  add(query_593073, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_593073, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_593073, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_593073, "Action", newJString(Action))
  add(query_593073, "CopyTags", newJBool(CopyTags))
  add(query_593073, "Version", newJString(Version))
  result = call_593072.call(nil, query_593073, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_593053(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_593054, base: "/",
    url: url_GetCopyDBClusterSnapshot_593055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_593129 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBCluster_593131(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBCluster_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = query.getOrDefault("Action")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_593132 != nil:
    section.add "Action", valid_593132
  var valid_593133 = query.getOrDefault("Version")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593133 != nil:
    section.add "Version", valid_593133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593134 = header.getOrDefault("X-Amz-Signature")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Signature", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Content-Sha256", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Date")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Date", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Credential")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Credential", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Security-Token")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Security-Token", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Algorithm")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Algorithm", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-SignedHeaders", valid_593140
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
  var valid_593141 = formData.getOrDefault("Port")
  valid_593141 = validateParameter(valid_593141, JInt, required = false, default = nil)
  if valid_593141 != nil:
    section.add "Port", valid_593141
  var valid_593142 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "PreferredMaintenanceWindow", valid_593142
  var valid_593143 = formData.getOrDefault("PreferredBackupWindow")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "PreferredBackupWindow", valid_593143
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_593144 = formData.getOrDefault("MasterUserPassword")
  valid_593144 = validateParameter(valid_593144, JString, required = true,
                                 default = nil)
  if valid_593144 != nil:
    section.add "MasterUserPassword", valid_593144
  var valid_593145 = formData.getOrDefault("MasterUsername")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = nil)
  if valid_593145 != nil:
    section.add "MasterUsername", valid_593145
  var valid_593146 = formData.getOrDefault("EngineVersion")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "EngineVersion", valid_593146
  var valid_593147 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_593147 = validateParameter(valid_593147, JArray, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "VpcSecurityGroupIds", valid_593147
  var valid_593148 = formData.getOrDefault("AvailabilityZones")
  valid_593148 = validateParameter(valid_593148, JArray, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "AvailabilityZones", valid_593148
  var valid_593149 = formData.getOrDefault("BackupRetentionPeriod")
  valid_593149 = validateParameter(valid_593149, JInt, required = false, default = nil)
  if valid_593149 != nil:
    section.add "BackupRetentionPeriod", valid_593149
  var valid_593150 = formData.getOrDefault("Engine")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "Engine", valid_593150
  var valid_593151 = formData.getOrDefault("KmsKeyId")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "KmsKeyId", valid_593151
  var valid_593152 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_593152 = validateParameter(valid_593152, JArray, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "EnableCloudwatchLogsExports", valid_593152
  var valid_593153 = formData.getOrDefault("Tags")
  valid_593153 = validateParameter(valid_593153, JArray, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "Tags", valid_593153
  var valid_593154 = formData.getOrDefault("DBSubnetGroupName")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "DBSubnetGroupName", valid_593154
  var valid_593155 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "DBClusterParameterGroupName", valid_593155
  var valid_593156 = formData.getOrDefault("StorageEncrypted")
  valid_593156 = validateParameter(valid_593156, JBool, required = false, default = nil)
  if valid_593156 != nil:
    section.add "StorageEncrypted", valid_593156
  var valid_593157 = formData.getOrDefault("DBClusterIdentifier")
  valid_593157 = validateParameter(valid_593157, JString, required = true,
                                 default = nil)
  if valid_593157 != nil:
    section.add "DBClusterIdentifier", valid_593157
  var valid_593158 = formData.getOrDefault("DeletionProtection")
  valid_593158 = validateParameter(valid_593158, JBool, required = false, default = nil)
  if valid_593158 != nil:
    section.add "DeletionProtection", valid_593158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593159: Call_PostCreateDBCluster_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_593159.validator(path, query, header, formData, body)
  let scheme = call_593159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593159.url(scheme.get, call_593159.host, call_593159.base,
                         call_593159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593159, url, valid)

proc call*(call_593160: Call_PostCreateDBCluster_593129;
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
  var query_593161 = newJObject()
  var formData_593162 = newJObject()
  add(formData_593162, "Port", newJInt(Port))
  add(formData_593162, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593162, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_593162, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_593162, "MasterUsername", newJString(MasterUsername))
  add(formData_593162, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_593162.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_593162.add "AvailabilityZones", AvailabilityZones
  add(formData_593162, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_593162, "Engine", newJString(Engine))
  add(formData_593162, "KmsKeyId", newJString(KmsKeyId))
  if EnableCloudwatchLogsExports != nil:
    formData_593162.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_593161, "Action", newJString(Action))
  if Tags != nil:
    formData_593162.add "Tags", Tags
  add(formData_593162, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593162, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593161, "Version", newJString(Version))
  add(formData_593162, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_593162, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_593162, "DeletionProtection", newJBool(DeletionProtection))
  result = call_593160.call(nil, query_593161, nil, formData_593162, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_593129(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_593130, base: "/",
    url: url_PostCreateDBCluster_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_593096 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBCluster_593098(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBCluster_593097(path: JsonNode; query: JsonNode;
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
  var valid_593099 = query.getOrDefault("StorageEncrypted")
  valid_593099 = validateParameter(valid_593099, JBool, required = false, default = nil)
  if valid_593099 != nil:
    section.add "StorageEncrypted", valid_593099
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_593100 = query.getOrDefault("Engine")
  valid_593100 = validateParameter(valid_593100, JString, required = true,
                                 default = nil)
  if valid_593100 != nil:
    section.add "Engine", valid_593100
  var valid_593101 = query.getOrDefault("DeletionProtection")
  valid_593101 = validateParameter(valid_593101, JBool, required = false, default = nil)
  if valid_593101 != nil:
    section.add "DeletionProtection", valid_593101
  var valid_593102 = query.getOrDefault("Tags")
  valid_593102 = validateParameter(valid_593102, JArray, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "Tags", valid_593102
  var valid_593103 = query.getOrDefault("KmsKeyId")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "KmsKeyId", valid_593103
  var valid_593104 = query.getOrDefault("DBClusterIdentifier")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "DBClusterIdentifier", valid_593104
  var valid_593105 = query.getOrDefault("DBClusterParameterGroupName")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "DBClusterParameterGroupName", valid_593105
  var valid_593106 = query.getOrDefault("AvailabilityZones")
  valid_593106 = validateParameter(valid_593106, JArray, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "AvailabilityZones", valid_593106
  var valid_593107 = query.getOrDefault("MasterUsername")
  valid_593107 = validateParameter(valid_593107, JString, required = true,
                                 default = nil)
  if valid_593107 != nil:
    section.add "MasterUsername", valid_593107
  var valid_593108 = query.getOrDefault("BackupRetentionPeriod")
  valid_593108 = validateParameter(valid_593108, JInt, required = false, default = nil)
  if valid_593108 != nil:
    section.add "BackupRetentionPeriod", valid_593108
  var valid_593109 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_593109 = validateParameter(valid_593109, JArray, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "EnableCloudwatchLogsExports", valid_593109
  var valid_593110 = query.getOrDefault("EngineVersion")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "EngineVersion", valid_593110
  var valid_593111 = query.getOrDefault("Action")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_593111 != nil:
    section.add "Action", valid_593111
  var valid_593112 = query.getOrDefault("Port")
  valid_593112 = validateParameter(valid_593112, JInt, required = false, default = nil)
  if valid_593112 != nil:
    section.add "Port", valid_593112
  var valid_593113 = query.getOrDefault("VpcSecurityGroupIds")
  valid_593113 = validateParameter(valid_593113, JArray, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "VpcSecurityGroupIds", valid_593113
  var valid_593114 = query.getOrDefault("MasterUserPassword")
  valid_593114 = validateParameter(valid_593114, JString, required = true,
                                 default = nil)
  if valid_593114 != nil:
    section.add "MasterUserPassword", valid_593114
  var valid_593115 = query.getOrDefault("DBSubnetGroupName")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "DBSubnetGroupName", valid_593115
  var valid_593116 = query.getOrDefault("PreferredBackupWindow")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "PreferredBackupWindow", valid_593116
  var valid_593117 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "PreferredMaintenanceWindow", valid_593117
  var valid_593118 = query.getOrDefault("Version")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593118 != nil:
    section.add "Version", valid_593118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593119 = header.getOrDefault("X-Amz-Signature")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Signature", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Content-Sha256", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Date")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Date", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Credential")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Credential", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Security-Token")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Security-Token", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Algorithm")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Algorithm", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-SignedHeaders", valid_593125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_GetCreateDBCluster_593096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_GetCreateDBCluster_593096; Engine: string;
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
  var query_593128 = newJObject()
  add(query_593128, "StorageEncrypted", newJBool(StorageEncrypted))
  add(query_593128, "Engine", newJString(Engine))
  add(query_593128, "DeletionProtection", newJBool(DeletionProtection))
  if Tags != nil:
    query_593128.add "Tags", Tags
  add(query_593128, "KmsKeyId", newJString(KmsKeyId))
  add(query_593128, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593128, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if AvailabilityZones != nil:
    query_593128.add "AvailabilityZones", AvailabilityZones
  add(query_593128, "MasterUsername", newJString(MasterUsername))
  add(query_593128, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if EnableCloudwatchLogsExports != nil:
    query_593128.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_593128, "EngineVersion", newJString(EngineVersion))
  add(query_593128, "Action", newJString(Action))
  add(query_593128, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_593128.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_593128, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_593128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593128, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_593128, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593128, "Version", newJString(Version))
  result = call_593127.call(nil, query_593128, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_593096(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_593097,
    base: "/", url: url_GetCreateDBCluster_593098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_593182 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBClusterParameterGroup_593184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_593183(path: JsonNode;
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
  var valid_593185 = query.getOrDefault("Action")
  valid_593185 = validateParameter(valid_593185, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_593185 != nil:
    section.add "Action", valid_593185
  var valid_593186 = query.getOrDefault("Version")
  valid_593186 = validateParameter(valid_593186, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593186 != nil:
    section.add "Version", valid_593186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Security-Token")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Security-Token", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Algorithm")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Algorithm", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-SignedHeaders", valid_593193
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
  var valid_593194 = formData.getOrDefault("Description")
  valid_593194 = validateParameter(valid_593194, JString, required = true,
                                 default = nil)
  if valid_593194 != nil:
    section.add "Description", valid_593194
  var valid_593195 = formData.getOrDefault("Tags")
  valid_593195 = validateParameter(valid_593195, JArray, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "Tags", valid_593195
  var valid_593196 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_593196 = validateParameter(valid_593196, JString, required = true,
                                 default = nil)
  if valid_593196 != nil:
    section.add "DBClusterParameterGroupName", valid_593196
  var valid_593197 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593197 = validateParameter(valid_593197, JString, required = true,
                                 default = nil)
  if valid_593197 != nil:
    section.add "DBParameterGroupFamily", valid_593197
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593198: Call_PostCreateDBClusterParameterGroup_593182;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_593198.validator(path, query, header, formData, body)
  let scheme = call_593198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593198.url(scheme.get, call_593198.host, call_593198.base,
                         call_593198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593198, url, valid)

proc call*(call_593199: Call_PostCreateDBClusterParameterGroup_593182;
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
  var query_593200 = newJObject()
  var formData_593201 = newJObject()
  add(formData_593201, "Description", newJString(Description))
  add(query_593200, "Action", newJString(Action))
  if Tags != nil:
    formData_593201.add "Tags", Tags
  add(formData_593201, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593200, "Version", newJString(Version))
  add(formData_593201, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593199.call(nil, query_593200, nil, formData_593201, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_593182(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_593183, base: "/",
    url: url_PostCreateDBClusterParameterGroup_593184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_593163 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBClusterParameterGroup_593165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_593164(path: JsonNode;
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
  var valid_593166 = query.getOrDefault("DBParameterGroupFamily")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "DBParameterGroupFamily", valid_593166
  var valid_593167 = query.getOrDefault("Tags")
  valid_593167 = validateParameter(valid_593167, JArray, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "Tags", valid_593167
  var valid_593168 = query.getOrDefault("DBClusterParameterGroupName")
  valid_593168 = validateParameter(valid_593168, JString, required = true,
                                 default = nil)
  if valid_593168 != nil:
    section.add "DBClusterParameterGroupName", valid_593168
  var valid_593169 = query.getOrDefault("Action")
  valid_593169 = validateParameter(valid_593169, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_593169 != nil:
    section.add "Action", valid_593169
  var valid_593170 = query.getOrDefault("Description")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "Description", valid_593170
  var valid_593171 = query.getOrDefault("Version")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593171 != nil:
    section.add "Version", valid_593171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_GetCreateDBClusterParameterGroup_593163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_GetCreateDBClusterParameterGroup_593163;
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
  var query_593181 = newJObject()
  add(query_593181, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_593181.add "Tags", Tags
  add(query_593181, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593181, "Action", newJString(Action))
  add(query_593181, "Description", newJString(Description))
  add(query_593181, "Version", newJString(Version))
  result = call_593180.call(nil, query_593181, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_593163(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_593164, base: "/",
    url: url_GetCreateDBClusterParameterGroup_593165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_593220 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBClusterSnapshot_593222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterSnapshot_593221(path: JsonNode; query: JsonNode;
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
  var valid_593223 = query.getOrDefault("Action")
  valid_593223 = validateParameter(valid_593223, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_593223 != nil:
    section.add "Action", valid_593223
  var valid_593224 = query.getOrDefault("Version")
  valid_593224 = validateParameter(valid_593224, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593224 != nil:
    section.add "Version", valid_593224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593225 = header.getOrDefault("X-Amz-Signature")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Signature", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Content-Sha256", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Date")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Date", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Credential")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Credential", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Security-Token")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Security-Token", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Algorithm")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Algorithm", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-SignedHeaders", valid_593231
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
  var valid_593232 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593232 = validateParameter(valid_593232, JString, required = true,
                                 default = nil)
  if valid_593232 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593232
  var valid_593233 = formData.getOrDefault("Tags")
  valid_593233 = validateParameter(valid_593233, JArray, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "Tags", valid_593233
  var valid_593234 = formData.getOrDefault("DBClusterIdentifier")
  valid_593234 = validateParameter(valid_593234, JString, required = true,
                                 default = nil)
  if valid_593234 != nil:
    section.add "DBClusterIdentifier", valid_593234
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593235: Call_PostCreateDBClusterSnapshot_593220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_593235.validator(path, query, header, formData, body)
  let scheme = call_593235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593235.url(scheme.get, call_593235.host, call_593235.base,
                         call_593235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593235, url, valid)

proc call*(call_593236: Call_PostCreateDBClusterSnapshot_593220;
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
  var query_593237 = newJObject()
  var formData_593238 = newJObject()
  add(formData_593238, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593237, "Action", newJString(Action))
  if Tags != nil:
    formData_593238.add "Tags", Tags
  add(query_593237, "Version", newJString(Version))
  add(formData_593238, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_593236.call(nil, query_593237, nil, formData_593238, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_593220(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_593221, base: "/",
    url: url_PostCreateDBClusterSnapshot_593222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_593202 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBClusterSnapshot_593204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterSnapshot_593203(path: JsonNode; query: JsonNode;
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
  var valid_593205 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593205
  var valid_593206 = query.getOrDefault("Tags")
  valid_593206 = validateParameter(valid_593206, JArray, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "Tags", valid_593206
  var valid_593207 = query.getOrDefault("DBClusterIdentifier")
  valid_593207 = validateParameter(valid_593207, JString, required = true,
                                 default = nil)
  if valid_593207 != nil:
    section.add "DBClusterIdentifier", valid_593207
  var valid_593208 = query.getOrDefault("Action")
  valid_593208 = validateParameter(valid_593208, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_593208 != nil:
    section.add "Action", valid_593208
  var valid_593209 = query.getOrDefault("Version")
  valid_593209 = validateParameter(valid_593209, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593209 != nil:
    section.add "Version", valid_593209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593210 = header.getOrDefault("X-Amz-Signature")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Signature", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Content-Sha256", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Date")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Date", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Credential")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Credential", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Security-Token")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Security-Token", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Algorithm")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Algorithm", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-SignedHeaders", valid_593216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593217: Call_GetCreateDBClusterSnapshot_593202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_593217.validator(path, query, header, formData, body)
  let scheme = call_593217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593217.url(scheme.get, call_593217.host, call_593217.base,
                         call_593217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593217, url, valid)

proc call*(call_593218: Call_GetCreateDBClusterSnapshot_593202;
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
  var query_593219 = newJObject()
  add(query_593219, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_593219.add "Tags", Tags
  add(query_593219, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593219, "Action", newJString(Action))
  add(query_593219, "Version", newJString(Version))
  result = call_593218.call(nil, query_593219, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_593202(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_593203, base: "/",
    url: url_GetCreateDBClusterSnapshot_593204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_593263 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstance_593265(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_593264(path: JsonNode; query: JsonNode;
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
  var valid_593266 = query.getOrDefault("Action")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593266 != nil:
    section.add "Action", valid_593266
  var valid_593267 = query.getOrDefault("Version")
  valid_593267 = validateParameter(valid_593267, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593267 != nil:
    section.add "Version", valid_593267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593268 = header.getOrDefault("X-Amz-Signature")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Signature", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Content-Sha256", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Date")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Date", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Credential")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Credential", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Security-Token")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Security-Token", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Algorithm")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Algorithm", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-SignedHeaders", valid_593274
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
  var valid_593275 = formData.getOrDefault("PromotionTier")
  valid_593275 = validateParameter(valid_593275, JInt, required = false, default = nil)
  if valid_593275 != nil:
    section.add "PromotionTier", valid_593275
  var valid_593276 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "PreferredMaintenanceWindow", valid_593276
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_593277 = formData.getOrDefault("DBInstanceClass")
  valid_593277 = validateParameter(valid_593277, JString, required = true,
                                 default = nil)
  if valid_593277 != nil:
    section.add "DBInstanceClass", valid_593277
  var valid_593278 = formData.getOrDefault("AvailabilityZone")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "AvailabilityZone", valid_593278
  var valid_593279 = formData.getOrDefault("Engine")
  valid_593279 = validateParameter(valid_593279, JString, required = true,
                                 default = nil)
  if valid_593279 != nil:
    section.add "Engine", valid_593279
  var valid_593280 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593280 = validateParameter(valid_593280, JBool, required = false, default = nil)
  if valid_593280 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593280
  var valid_593281 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593281 = validateParameter(valid_593281, JString, required = true,
                                 default = nil)
  if valid_593281 != nil:
    section.add "DBInstanceIdentifier", valid_593281
  var valid_593282 = formData.getOrDefault("Tags")
  valid_593282 = validateParameter(valid_593282, JArray, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "Tags", valid_593282
  var valid_593283 = formData.getOrDefault("DBClusterIdentifier")
  valid_593283 = validateParameter(valid_593283, JString, required = true,
                                 default = nil)
  if valid_593283 != nil:
    section.add "DBClusterIdentifier", valid_593283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_PostCreateDBInstance_593263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_PostCreateDBInstance_593263; DBInstanceClass: string;
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
  var query_593286 = newJObject()
  var formData_593287 = newJObject()
  add(formData_593287, "PromotionTier", newJInt(PromotionTier))
  add(formData_593287, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593287, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593287, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593287, "Engine", newJString(Engine))
  add(formData_593287, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593287, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593286, "Action", newJString(Action))
  if Tags != nil:
    formData_593287.add "Tags", Tags
  add(query_593286, "Version", newJString(Version))
  add(formData_593287, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_593285.call(nil, query_593286, nil, formData_593287, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_593263(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_593264, base: "/",
    url: url_PostCreateDBInstance_593265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_593239 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstance_593241(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_593240(path: JsonNode; query: JsonNode;
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
  var valid_593242 = query.getOrDefault("Engine")
  valid_593242 = validateParameter(valid_593242, JString, required = true,
                                 default = nil)
  if valid_593242 != nil:
    section.add "Engine", valid_593242
  var valid_593243 = query.getOrDefault("Tags")
  valid_593243 = validateParameter(valid_593243, JArray, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "Tags", valid_593243
  var valid_593244 = query.getOrDefault("DBClusterIdentifier")
  valid_593244 = validateParameter(valid_593244, JString, required = true,
                                 default = nil)
  if valid_593244 != nil:
    section.add "DBClusterIdentifier", valid_593244
  var valid_593245 = query.getOrDefault("DBInstanceIdentifier")
  valid_593245 = validateParameter(valid_593245, JString, required = true,
                                 default = nil)
  if valid_593245 != nil:
    section.add "DBInstanceIdentifier", valid_593245
  var valid_593246 = query.getOrDefault("PromotionTier")
  valid_593246 = validateParameter(valid_593246, JInt, required = false, default = nil)
  if valid_593246 != nil:
    section.add "PromotionTier", valid_593246
  var valid_593247 = query.getOrDefault("Action")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593247 != nil:
    section.add "Action", valid_593247
  var valid_593248 = query.getOrDefault("AvailabilityZone")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "AvailabilityZone", valid_593248
  var valid_593249 = query.getOrDefault("Version")
  valid_593249 = validateParameter(valid_593249, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593249 != nil:
    section.add "Version", valid_593249
  var valid_593250 = query.getOrDefault("DBInstanceClass")
  valid_593250 = validateParameter(valid_593250, JString, required = true,
                                 default = nil)
  if valid_593250 != nil:
    section.add "DBInstanceClass", valid_593250
  var valid_593251 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "PreferredMaintenanceWindow", valid_593251
  var valid_593252 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593252 = validateParameter(valid_593252, JBool, required = false, default = nil)
  if valid_593252 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593253 = header.getOrDefault("X-Amz-Signature")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Signature", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Content-Sha256", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Date")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Date", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Credential")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Credential", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Security-Token")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Security-Token", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Algorithm")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Algorithm", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-SignedHeaders", valid_593259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593260: Call_GetCreateDBInstance_593239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_593260.validator(path, query, header, formData, body)
  let scheme = call_593260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593260.url(scheme.get, call_593260.host, call_593260.base,
                         call_593260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593260, url, valid)

proc call*(call_593261: Call_GetCreateDBInstance_593239; Engine: string;
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
  var query_593262 = newJObject()
  add(query_593262, "Engine", newJString(Engine))
  if Tags != nil:
    query_593262.add "Tags", Tags
  add(query_593262, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593262, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593262, "PromotionTier", newJInt(PromotionTier))
  add(query_593262, "Action", newJString(Action))
  add(query_593262, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593262, "Version", newJString(Version))
  add(query_593262, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593262, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593262, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_593261.call(nil, query_593262, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_593239(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_593240, base: "/",
    url: url_GetCreateDBInstance_593241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_593307 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSubnetGroup_593309(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_593308(path: JsonNode; query: JsonNode;
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
  var valid_593310 = query.getOrDefault("Action")
  valid_593310 = validateParameter(valid_593310, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593310 != nil:
    section.add "Action", valid_593310
  var valid_593311 = query.getOrDefault("Version")
  valid_593311 = validateParameter(valid_593311, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593311 != nil:
    section.add "Version", valid_593311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593312 = header.getOrDefault("X-Amz-Signature")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Signature", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Content-Sha256", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Date")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Date", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Credential")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Credential", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Security-Token")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Security-Token", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Algorithm")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Algorithm", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-SignedHeaders", valid_593318
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
  var valid_593319 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = nil)
  if valid_593319 != nil:
    section.add "DBSubnetGroupDescription", valid_593319
  var valid_593320 = formData.getOrDefault("Tags")
  valid_593320 = validateParameter(valid_593320, JArray, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "Tags", valid_593320
  var valid_593321 = formData.getOrDefault("DBSubnetGroupName")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = nil)
  if valid_593321 != nil:
    section.add "DBSubnetGroupName", valid_593321
  var valid_593322 = formData.getOrDefault("SubnetIds")
  valid_593322 = validateParameter(valid_593322, JArray, required = true, default = nil)
  if valid_593322 != nil:
    section.add "SubnetIds", valid_593322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593323: Call_PostCreateDBSubnetGroup_593307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_593323.validator(path, query, header, formData, body)
  let scheme = call_593323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593323.url(scheme.get, call_593323.host, call_593323.base,
                         call_593323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593323, url, valid)

proc call*(call_593324: Call_PostCreateDBSubnetGroup_593307;
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
  var query_593325 = newJObject()
  var formData_593326 = newJObject()
  add(formData_593326, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593325, "Action", newJString(Action))
  if Tags != nil:
    formData_593326.add "Tags", Tags
  add(formData_593326, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593325, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_593326.add "SubnetIds", SubnetIds
  result = call_593324.call(nil, query_593325, nil, formData_593326, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_593307(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_593308, base: "/",
    url: url_PostCreateDBSubnetGroup_593309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_593288 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSubnetGroup_593290(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_593289(path: JsonNode; query: JsonNode;
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
  var valid_593291 = query.getOrDefault("Tags")
  valid_593291 = validateParameter(valid_593291, JArray, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "Tags", valid_593291
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_593292 = query.getOrDefault("SubnetIds")
  valid_593292 = validateParameter(valid_593292, JArray, required = true, default = nil)
  if valid_593292 != nil:
    section.add "SubnetIds", valid_593292
  var valid_593293 = query.getOrDefault("Action")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593293 != nil:
    section.add "Action", valid_593293
  var valid_593294 = query.getOrDefault("DBSubnetGroupDescription")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = nil)
  if valid_593294 != nil:
    section.add "DBSubnetGroupDescription", valid_593294
  var valid_593295 = query.getOrDefault("DBSubnetGroupName")
  valid_593295 = validateParameter(valid_593295, JString, required = true,
                                 default = nil)
  if valid_593295 != nil:
    section.add "DBSubnetGroupName", valid_593295
  var valid_593296 = query.getOrDefault("Version")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593296 != nil:
    section.add "Version", valid_593296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593297 = header.getOrDefault("X-Amz-Signature")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Signature", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Content-Sha256", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Date")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Date", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Credential")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Credential", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Security-Token")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Security-Token", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Algorithm")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Algorithm", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-SignedHeaders", valid_593303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593304: Call_GetCreateDBSubnetGroup_593288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_593304.validator(path, query, header, formData, body)
  let scheme = call_593304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593304.url(scheme.get, call_593304.host, call_593304.base,
                         call_593304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593304, url, valid)

proc call*(call_593305: Call_GetCreateDBSubnetGroup_593288; SubnetIds: JsonNode;
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
  var query_593306 = newJObject()
  if Tags != nil:
    query_593306.add "Tags", Tags
  if SubnetIds != nil:
    query_593306.add "SubnetIds", SubnetIds
  add(query_593306, "Action", newJString(Action))
  add(query_593306, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593306, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593306, "Version", newJString(Version))
  result = call_593305.call(nil, query_593306, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_593288(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_593289, base: "/",
    url: url_GetCreateDBSubnetGroup_593290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_593345 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBCluster_593347(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBCluster_593346(path: JsonNode; query: JsonNode;
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
  var valid_593348 = query.getOrDefault("Action")
  valid_593348 = validateParameter(valid_593348, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_593348 != nil:
    section.add "Action", valid_593348
  var valid_593349 = query.getOrDefault("Version")
  valid_593349 = validateParameter(valid_593349, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593349 != nil:
    section.add "Version", valid_593349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593350 = header.getOrDefault("X-Amz-Signature")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Signature", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Content-Sha256", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Date")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Date", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Credential")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Credential", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Security-Token")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Security-Token", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Algorithm")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Algorithm", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-SignedHeaders", valid_593356
  result.add "header", section
  ## parameters in `formData` object:
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_593357 = formData.getOrDefault("SkipFinalSnapshot")
  valid_593357 = validateParameter(valid_593357, JBool, required = false, default = nil)
  if valid_593357 != nil:
    section.add "SkipFinalSnapshot", valid_593357
  var valid_593358 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593358
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_593359 = formData.getOrDefault("DBClusterIdentifier")
  valid_593359 = validateParameter(valid_593359, JString, required = true,
                                 default = nil)
  if valid_593359 != nil:
    section.add "DBClusterIdentifier", valid_593359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593360: Call_PostDeleteDBCluster_593345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_593360.validator(path, query, header, formData, body)
  let scheme = call_593360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593360.url(scheme.get, call_593360.host, call_593360.base,
                         call_593360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593360, url, valid)

proc call*(call_593361: Call_PostDeleteDBCluster_593345;
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
  var query_593362 = newJObject()
  var formData_593363 = newJObject()
  add(query_593362, "Action", newJString(Action))
  add(formData_593363, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_593363, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_593362, "Version", newJString(Version))
  add(formData_593363, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_593361.call(nil, query_593362, nil, formData_593363, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_593345(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_593346, base: "/",
    url: url_PostDeleteDBCluster_593347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_593327 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBCluster_593329(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBCluster_593328(path: JsonNode; query: JsonNode;
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
  var valid_593330 = query.getOrDefault("DBClusterIdentifier")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = nil)
  if valid_593330 != nil:
    section.add "DBClusterIdentifier", valid_593330
  var valid_593331 = query.getOrDefault("SkipFinalSnapshot")
  valid_593331 = validateParameter(valid_593331, JBool, required = false, default = nil)
  if valid_593331 != nil:
    section.add "SkipFinalSnapshot", valid_593331
  var valid_593332 = query.getOrDefault("Action")
  valid_593332 = validateParameter(valid_593332, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_593332 != nil:
    section.add "Action", valid_593332
  var valid_593333 = query.getOrDefault("Version")
  valid_593333 = validateParameter(valid_593333, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593333 != nil:
    section.add "Version", valid_593333
  var valid_593334 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593335 = header.getOrDefault("X-Amz-Signature")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Signature", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Content-Sha256", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Date")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Date", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Credential")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Credential", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Security-Token")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Security-Token", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Algorithm")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Algorithm", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-SignedHeaders", valid_593341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593342: Call_GetDeleteDBCluster_593327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_593342.validator(path, query, header, formData, body)
  let scheme = call_593342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593342.url(scheme.get, call_593342.host, call_593342.base,
                         call_593342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593342, url, valid)

proc call*(call_593343: Call_GetDeleteDBCluster_593327;
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
  var query_593344 = newJObject()
  add(query_593344, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593344, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_593344, "Action", newJString(Action))
  add(query_593344, "Version", newJString(Version))
  add(query_593344, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_593343.call(nil, query_593344, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_593327(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_593328,
    base: "/", url: url_GetDeleteDBCluster_593329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_593380 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBClusterParameterGroup_593382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_593381(path: JsonNode;
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
  var valid_593383 = query.getOrDefault("Action")
  valid_593383 = validateParameter(valid_593383, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_593383 != nil:
    section.add "Action", valid_593383
  var valid_593384 = query.getOrDefault("Version")
  valid_593384 = validateParameter(valid_593384, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593384 != nil:
    section.add "Version", valid_593384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593385 = header.getOrDefault("X-Amz-Signature")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Signature", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Content-Sha256", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Date")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Date", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Credential")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Credential", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Security-Token")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Security-Token", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Algorithm")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Algorithm", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-SignedHeaders", valid_593391
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_593392 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_593392 = validateParameter(valid_593392, JString, required = true,
                                 default = nil)
  if valid_593392 != nil:
    section.add "DBClusterParameterGroupName", valid_593392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593393: Call_PostDeleteDBClusterParameterGroup_593380;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_593393.validator(path, query, header, formData, body)
  let scheme = call_593393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593393.url(scheme.get, call_593393.host, call_593393.base,
                         call_593393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593393, url, valid)

proc call*(call_593394: Call_PostDeleteDBClusterParameterGroup_593380;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_593395 = newJObject()
  var formData_593396 = newJObject()
  add(query_593395, "Action", newJString(Action))
  add(formData_593396, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593395, "Version", newJString(Version))
  result = call_593394.call(nil, query_593395, nil, formData_593396, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_593380(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_593381, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_593382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_593364 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBClusterParameterGroup_593366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_593365(path: JsonNode;
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
  var valid_593367 = query.getOrDefault("DBClusterParameterGroupName")
  valid_593367 = validateParameter(valid_593367, JString, required = true,
                                 default = nil)
  if valid_593367 != nil:
    section.add "DBClusterParameterGroupName", valid_593367
  var valid_593368 = query.getOrDefault("Action")
  valid_593368 = validateParameter(valid_593368, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_593368 != nil:
    section.add "Action", valid_593368
  var valid_593369 = query.getOrDefault("Version")
  valid_593369 = validateParameter(valid_593369, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593369 != nil:
    section.add "Version", valid_593369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593370 = header.getOrDefault("X-Amz-Signature")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Signature", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Content-Sha256", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Date")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Date", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Credential")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Credential", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Security-Token")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Security-Token", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Algorithm")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Algorithm", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-SignedHeaders", valid_593376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593377: Call_GetDeleteDBClusterParameterGroup_593364;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_593377.validator(path, query, header, formData, body)
  let scheme = call_593377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593377.url(scheme.get, call_593377.host, call_593377.base,
                         call_593377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593377, url, valid)

proc call*(call_593378: Call_GetDeleteDBClusterParameterGroup_593364;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593379 = newJObject()
  add(query_593379, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593379, "Action", newJString(Action))
  add(query_593379, "Version", newJString(Version))
  result = call_593378.call(nil, query_593379, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_593364(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_593365, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_593366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_593413 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBClusterSnapshot_593415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_593414(path: JsonNode; query: JsonNode;
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
  var valid_593416 = query.getOrDefault("Action")
  valid_593416 = validateParameter(valid_593416, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_593416 != nil:
    section.add "Action", valid_593416
  var valid_593417 = query.getOrDefault("Version")
  valid_593417 = validateParameter(valid_593417, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593417 != nil:
    section.add "Version", valid_593417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593418 = header.getOrDefault("X-Amz-Signature")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Signature", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Content-Sha256", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Date")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Date", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Credential")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Credential", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Security-Token")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Security-Token", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Algorithm")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Algorithm", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-SignedHeaders", valid_593424
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_593425 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593425 = validateParameter(valid_593425, JString, required = true,
                                 default = nil)
  if valid_593425 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593426: Call_PostDeleteDBClusterSnapshot_593413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_593426.validator(path, query, header, formData, body)
  let scheme = call_593426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593426.url(scheme.get, call_593426.host, call_593426.base,
                         call_593426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593426, url, valid)

proc call*(call_593427: Call_PostDeleteDBClusterSnapshot_593413;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593428 = newJObject()
  var formData_593429 = newJObject()
  add(formData_593429, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593428, "Action", newJString(Action))
  add(query_593428, "Version", newJString(Version))
  result = call_593427.call(nil, query_593428, nil, formData_593429, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_593413(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_593414, base: "/",
    url: url_PostDeleteDBClusterSnapshot_593415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_593397 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBClusterSnapshot_593399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_593398(path: JsonNode; query: JsonNode;
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
  var valid_593400 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593400 = validateParameter(valid_593400, JString, required = true,
                                 default = nil)
  if valid_593400 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593400
  var valid_593401 = query.getOrDefault("Action")
  valid_593401 = validateParameter(valid_593401, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_593401 != nil:
    section.add "Action", valid_593401
  var valid_593402 = query.getOrDefault("Version")
  valid_593402 = validateParameter(valid_593402, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593402 != nil:
    section.add "Version", valid_593402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593403 = header.getOrDefault("X-Amz-Signature")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Signature", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Content-Sha256", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Date")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Date", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Credential")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Credential", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Security-Token")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Security-Token", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Algorithm")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Algorithm", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-SignedHeaders", valid_593409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593410: Call_GetDeleteDBClusterSnapshot_593397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_593410.validator(path, query, header, formData, body)
  let scheme = call_593410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593410.url(scheme.get, call_593410.host, call_593410.base,
                         call_593410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593410, url, valid)

proc call*(call_593411: Call_GetDeleteDBClusterSnapshot_593397;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593412 = newJObject()
  add(query_593412, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593412, "Action", newJString(Action))
  add(query_593412, "Version", newJString(Version))
  result = call_593411.call(nil, query_593412, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_593397(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_593398, base: "/",
    url: url_GetDeleteDBClusterSnapshot_593399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_593446 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBInstance_593448(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_593447(path: JsonNode; query: JsonNode;
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
  var valid_593449 = query.getOrDefault("Action")
  valid_593449 = validateParameter(valid_593449, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593449 != nil:
    section.add "Action", valid_593449
  var valid_593450 = query.getOrDefault("Version")
  valid_593450 = validateParameter(valid_593450, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593450 != nil:
    section.add "Version", valid_593450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593451 = header.getOrDefault("X-Amz-Signature")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Signature", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Content-Sha256", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Date")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Date", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Credential")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Credential", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Security-Token")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Security-Token", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Algorithm")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Algorithm", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-SignedHeaders", valid_593457
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593458 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593458 = validateParameter(valid_593458, JString, required = true,
                                 default = nil)
  if valid_593458 != nil:
    section.add "DBInstanceIdentifier", valid_593458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593459: Call_PostDeleteDBInstance_593446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_593459.validator(path, query, header, formData, body)
  let scheme = call_593459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593459.url(scheme.get, call_593459.host, call_593459.base,
                         call_593459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593459, url, valid)

proc call*(call_593460: Call_PostDeleteDBInstance_593446;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593461 = newJObject()
  var formData_593462 = newJObject()
  add(formData_593462, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593461, "Action", newJString(Action))
  add(query_593461, "Version", newJString(Version))
  result = call_593460.call(nil, query_593461, nil, formData_593462, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_593446(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_593447, base: "/",
    url: url_PostDeleteDBInstance_593448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_593430 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBInstance_593432(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_593431(path: JsonNode; query: JsonNode;
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
  var valid_593433 = query.getOrDefault("DBInstanceIdentifier")
  valid_593433 = validateParameter(valid_593433, JString, required = true,
                                 default = nil)
  if valid_593433 != nil:
    section.add "DBInstanceIdentifier", valid_593433
  var valid_593434 = query.getOrDefault("Action")
  valid_593434 = validateParameter(valid_593434, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593434 != nil:
    section.add "Action", valid_593434
  var valid_593435 = query.getOrDefault("Version")
  valid_593435 = validateParameter(valid_593435, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593435 != nil:
    section.add "Version", valid_593435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593436 = header.getOrDefault("X-Amz-Signature")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Signature", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Content-Sha256", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Date")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Date", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Credential")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Credential", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Security-Token")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Security-Token", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Algorithm")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Algorithm", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-SignedHeaders", valid_593442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593443: Call_GetDeleteDBInstance_593430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_593443.validator(path, query, header, formData, body)
  let scheme = call_593443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593443.url(scheme.get, call_593443.host, call_593443.base,
                         call_593443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593443, url, valid)

proc call*(call_593444: Call_GetDeleteDBInstance_593430;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593445 = newJObject()
  add(query_593445, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593445, "Action", newJString(Action))
  add(query_593445, "Version", newJString(Version))
  result = call_593444.call(nil, query_593445, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_593430(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_593431, base: "/",
    url: url_GetDeleteDBInstance_593432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_593479 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSubnetGroup_593481(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_593480(path: JsonNode; query: JsonNode;
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
  var valid_593482 = query.getOrDefault("Action")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593482 != nil:
    section.add "Action", valid_593482
  var valid_593483 = query.getOrDefault("Version")
  valid_593483 = validateParameter(valid_593483, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593483 != nil:
    section.add "Version", valid_593483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593484 = header.getOrDefault("X-Amz-Signature")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Signature", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Content-Sha256", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Date")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Date", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Credential")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Credential", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Security-Token")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Security-Token", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Algorithm")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Algorithm", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-SignedHeaders", valid_593490
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_593491 = formData.getOrDefault("DBSubnetGroupName")
  valid_593491 = validateParameter(valid_593491, JString, required = true,
                                 default = nil)
  if valid_593491 != nil:
    section.add "DBSubnetGroupName", valid_593491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_PostDeleteDBSubnetGroup_593479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_PostDeleteDBSubnetGroup_593479;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_593494 = newJObject()
  var formData_593495 = newJObject()
  add(query_593494, "Action", newJString(Action))
  add(formData_593495, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593494, "Version", newJString(Version))
  result = call_593493.call(nil, query_593494, nil, formData_593495, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_593479(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_593480, base: "/",
    url: url_PostDeleteDBSubnetGroup_593481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_593463 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSubnetGroup_593465(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_593464(path: JsonNode; query: JsonNode;
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
  var valid_593466 = query.getOrDefault("Action")
  valid_593466 = validateParameter(valid_593466, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593466 != nil:
    section.add "Action", valid_593466
  var valid_593467 = query.getOrDefault("DBSubnetGroupName")
  valid_593467 = validateParameter(valid_593467, JString, required = true,
                                 default = nil)
  if valid_593467 != nil:
    section.add "DBSubnetGroupName", valid_593467
  var valid_593468 = query.getOrDefault("Version")
  valid_593468 = validateParameter(valid_593468, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593468 != nil:
    section.add "Version", valid_593468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593469 = header.getOrDefault("X-Amz-Signature")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Signature", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Content-Sha256", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Date")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Date", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Credential")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Credential", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Security-Token")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Security-Token", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Algorithm")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Algorithm", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-SignedHeaders", valid_593475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593476: Call_GetDeleteDBSubnetGroup_593463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_593476.validator(path, query, header, formData, body)
  let scheme = call_593476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593476.url(scheme.get, call_593476.host, call_593476.base,
                         call_593476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593476, url, valid)

proc call*(call_593477: Call_GetDeleteDBSubnetGroup_593463;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_593478 = newJObject()
  add(query_593478, "Action", newJString(Action))
  add(query_593478, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593478, "Version", newJString(Version))
  result = call_593477.call(nil, query_593478, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_593463(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_593464, base: "/",
    url: url_GetDeleteDBSubnetGroup_593465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_593515 = ref object of OpenApiRestCall_592348
proc url_PostDescribeCertificates_593517(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeCertificates_593516(path: JsonNode; query: JsonNode;
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
  var valid_593518 = query.getOrDefault("Action")
  valid_593518 = validateParameter(valid_593518, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_593518 != nil:
    section.add "Action", valid_593518
  var valid_593519 = query.getOrDefault("Version")
  valid_593519 = validateParameter(valid_593519, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593519 != nil:
    section.add "Version", valid_593519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593520 = header.getOrDefault("X-Amz-Signature")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Signature", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Content-Sha256", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Date")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Date", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Credential")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Credential", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Security-Token")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Security-Token", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Algorithm")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Algorithm", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-SignedHeaders", valid_593526
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
  var valid_593527 = formData.getOrDefault("MaxRecords")
  valid_593527 = validateParameter(valid_593527, JInt, required = false, default = nil)
  if valid_593527 != nil:
    section.add "MaxRecords", valid_593527
  var valid_593528 = formData.getOrDefault("Marker")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "Marker", valid_593528
  var valid_593529 = formData.getOrDefault("CertificateIdentifier")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "CertificateIdentifier", valid_593529
  var valid_593530 = formData.getOrDefault("Filters")
  valid_593530 = validateParameter(valid_593530, JArray, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "Filters", valid_593530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593531: Call_PostDescribeCertificates_593515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_593531.validator(path, query, header, formData, body)
  let scheme = call_593531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593531.url(scheme.get, call_593531.host, call_593531.base,
                         call_593531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593531, url, valid)

proc call*(call_593532: Call_PostDescribeCertificates_593515; MaxRecords: int = 0;
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
  var query_593533 = newJObject()
  var formData_593534 = newJObject()
  add(formData_593534, "MaxRecords", newJInt(MaxRecords))
  add(formData_593534, "Marker", newJString(Marker))
  add(formData_593534, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_593533, "Action", newJString(Action))
  if Filters != nil:
    formData_593534.add "Filters", Filters
  add(query_593533, "Version", newJString(Version))
  result = call_593532.call(nil, query_593533, nil, formData_593534, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_593515(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_593516, base: "/",
    url: url_PostDescribeCertificates_593517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_593496 = ref object of OpenApiRestCall_592348
proc url_GetDescribeCertificates_593498(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeCertificates_593497(path: JsonNode; query: JsonNode;
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
  var valid_593499 = query.getOrDefault("Marker")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "Marker", valid_593499
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593500 = query.getOrDefault("Action")
  valid_593500 = validateParameter(valid_593500, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_593500 != nil:
    section.add "Action", valid_593500
  var valid_593501 = query.getOrDefault("Version")
  valid_593501 = validateParameter(valid_593501, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593501 != nil:
    section.add "Version", valid_593501
  var valid_593502 = query.getOrDefault("CertificateIdentifier")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "CertificateIdentifier", valid_593502
  var valid_593503 = query.getOrDefault("Filters")
  valid_593503 = validateParameter(valid_593503, JArray, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "Filters", valid_593503
  var valid_593504 = query.getOrDefault("MaxRecords")
  valid_593504 = validateParameter(valid_593504, JInt, required = false, default = nil)
  if valid_593504 != nil:
    section.add "MaxRecords", valid_593504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593505 = header.getOrDefault("X-Amz-Signature")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Signature", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Content-Sha256", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Date")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Date", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Credential")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Credential", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Security-Token")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Security-Token", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Algorithm")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Algorithm", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-SignedHeaders", valid_593511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593512: Call_GetDescribeCertificates_593496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_593512.validator(path, query, header, formData, body)
  let scheme = call_593512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593512.url(scheme.get, call_593512.host, call_593512.base,
                         call_593512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593512, url, valid)

proc call*(call_593513: Call_GetDescribeCertificates_593496; Marker: string = "";
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
  var query_593514 = newJObject()
  add(query_593514, "Marker", newJString(Marker))
  add(query_593514, "Action", newJString(Action))
  add(query_593514, "Version", newJString(Version))
  add(query_593514, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_593514.add "Filters", Filters
  add(query_593514, "MaxRecords", newJInt(MaxRecords))
  result = call_593513.call(nil, query_593514, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_593496(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_593497, base: "/",
    url: url_GetDescribeCertificates_593498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_593554 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBClusterParameterGroups_593556(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_593555(path: JsonNode;
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
  var valid_593557 = query.getOrDefault("Action")
  valid_593557 = validateParameter(valid_593557, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_593557 != nil:
    section.add "Action", valid_593557
  var valid_593558 = query.getOrDefault("Version")
  valid_593558 = validateParameter(valid_593558, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593558 != nil:
    section.add "Version", valid_593558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593559 = header.getOrDefault("X-Amz-Signature")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Signature", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Content-Sha256", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Date")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Date", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Credential")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Credential", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Security-Token")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Security-Token", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Algorithm")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Algorithm", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-SignedHeaders", valid_593565
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
  var valid_593566 = formData.getOrDefault("MaxRecords")
  valid_593566 = validateParameter(valid_593566, JInt, required = false, default = nil)
  if valid_593566 != nil:
    section.add "MaxRecords", valid_593566
  var valid_593567 = formData.getOrDefault("Marker")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "Marker", valid_593567
  var valid_593568 = formData.getOrDefault("Filters")
  valid_593568 = validateParameter(valid_593568, JArray, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "Filters", valid_593568
  var valid_593569 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "DBClusterParameterGroupName", valid_593569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593570: Call_PostDescribeDBClusterParameterGroups_593554;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_593570.validator(path, query, header, formData, body)
  let scheme = call_593570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593570.url(scheme.get, call_593570.host, call_593570.base,
                         call_593570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593570, url, valid)

proc call*(call_593571: Call_PostDescribeDBClusterParameterGroups_593554;
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
  var query_593572 = newJObject()
  var formData_593573 = newJObject()
  add(formData_593573, "MaxRecords", newJInt(MaxRecords))
  add(formData_593573, "Marker", newJString(Marker))
  add(query_593572, "Action", newJString(Action))
  if Filters != nil:
    formData_593573.add "Filters", Filters
  add(formData_593573, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593572, "Version", newJString(Version))
  result = call_593571.call(nil, query_593572, nil, formData_593573, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_593554(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_593555, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_593556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_593535 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBClusterParameterGroups_593537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_593536(path: JsonNode;
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
  var valid_593538 = query.getOrDefault("Marker")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "Marker", valid_593538
  var valid_593539 = query.getOrDefault("DBClusterParameterGroupName")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "DBClusterParameterGroupName", valid_593539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593540 = query.getOrDefault("Action")
  valid_593540 = validateParameter(valid_593540, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_593540 != nil:
    section.add "Action", valid_593540
  var valid_593541 = query.getOrDefault("Version")
  valid_593541 = validateParameter(valid_593541, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593541 != nil:
    section.add "Version", valid_593541
  var valid_593542 = query.getOrDefault("Filters")
  valid_593542 = validateParameter(valid_593542, JArray, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "Filters", valid_593542
  var valid_593543 = query.getOrDefault("MaxRecords")
  valid_593543 = validateParameter(valid_593543, JInt, required = false, default = nil)
  if valid_593543 != nil:
    section.add "MaxRecords", valid_593543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593544 = header.getOrDefault("X-Amz-Signature")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Signature", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Content-Sha256", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Date")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Date", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Credential")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Credential", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Security-Token")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Security-Token", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Algorithm")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Algorithm", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-SignedHeaders", valid_593550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593551: Call_GetDescribeDBClusterParameterGroups_593535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_593551.validator(path, query, header, formData, body)
  let scheme = call_593551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593551.url(scheme.get, call_593551.host, call_593551.base,
                         call_593551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593551, url, valid)

proc call*(call_593552: Call_GetDescribeDBClusterParameterGroups_593535;
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
  var query_593553 = newJObject()
  add(query_593553, "Marker", newJString(Marker))
  add(query_593553, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593553, "Action", newJString(Action))
  add(query_593553, "Version", newJString(Version))
  if Filters != nil:
    query_593553.add "Filters", Filters
  add(query_593553, "MaxRecords", newJInt(MaxRecords))
  result = call_593552.call(nil, query_593553, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_593535(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_593536, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_593537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_593594 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBClusterParameters_593596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameters_593595(path: JsonNode;
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
  var valid_593597 = query.getOrDefault("Action")
  valid_593597 = validateParameter(valid_593597, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_593597 != nil:
    section.add "Action", valid_593597
  var valid_593598 = query.getOrDefault("Version")
  valid_593598 = validateParameter(valid_593598, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593598 != nil:
    section.add "Version", valid_593598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593599 = header.getOrDefault("X-Amz-Signature")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Signature", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Content-Sha256", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Date")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Date", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Credential")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Credential", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Security-Token")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Security-Token", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Algorithm")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Algorithm", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-SignedHeaders", valid_593605
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
  var valid_593606 = formData.getOrDefault("Source")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "Source", valid_593606
  var valid_593607 = formData.getOrDefault("MaxRecords")
  valid_593607 = validateParameter(valid_593607, JInt, required = false, default = nil)
  if valid_593607 != nil:
    section.add "MaxRecords", valid_593607
  var valid_593608 = formData.getOrDefault("Marker")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "Marker", valid_593608
  var valid_593609 = formData.getOrDefault("Filters")
  valid_593609 = validateParameter(valid_593609, JArray, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "Filters", valid_593609
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_593610 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_593610 = validateParameter(valid_593610, JString, required = true,
                                 default = nil)
  if valid_593610 != nil:
    section.add "DBClusterParameterGroupName", valid_593610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593611: Call_PostDescribeDBClusterParameters_593594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_593611.validator(path, query, header, formData, body)
  let scheme = call_593611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593611.url(scheme.get, call_593611.host, call_593611.base,
                         call_593611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593611, url, valid)

proc call*(call_593612: Call_PostDescribeDBClusterParameters_593594;
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
  var query_593613 = newJObject()
  var formData_593614 = newJObject()
  add(formData_593614, "Source", newJString(Source))
  add(formData_593614, "MaxRecords", newJInt(MaxRecords))
  add(formData_593614, "Marker", newJString(Marker))
  add(query_593613, "Action", newJString(Action))
  if Filters != nil:
    formData_593614.add "Filters", Filters
  add(formData_593614, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593613, "Version", newJString(Version))
  result = call_593612.call(nil, query_593613, nil, formData_593614, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_593594(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_593595, base: "/",
    url: url_PostDescribeDBClusterParameters_593596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_593574 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBClusterParameters_593576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameters_593575(path: JsonNode;
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
  var valid_593577 = query.getOrDefault("Marker")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "Marker", valid_593577
  var valid_593578 = query.getOrDefault("Source")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "Source", valid_593578
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_593579 = query.getOrDefault("DBClusterParameterGroupName")
  valid_593579 = validateParameter(valid_593579, JString, required = true,
                                 default = nil)
  if valid_593579 != nil:
    section.add "DBClusterParameterGroupName", valid_593579
  var valid_593580 = query.getOrDefault("Action")
  valid_593580 = validateParameter(valid_593580, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_593580 != nil:
    section.add "Action", valid_593580
  var valid_593581 = query.getOrDefault("Version")
  valid_593581 = validateParameter(valid_593581, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593581 != nil:
    section.add "Version", valid_593581
  var valid_593582 = query.getOrDefault("Filters")
  valid_593582 = validateParameter(valid_593582, JArray, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "Filters", valid_593582
  var valid_593583 = query.getOrDefault("MaxRecords")
  valid_593583 = validateParameter(valid_593583, JInt, required = false, default = nil)
  if valid_593583 != nil:
    section.add "MaxRecords", valid_593583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593584 = header.getOrDefault("X-Amz-Signature")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Signature", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Content-Sha256", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Date")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Date", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Credential")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Credential", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Security-Token")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Security-Token", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Algorithm")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Algorithm", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-SignedHeaders", valid_593590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593591: Call_GetDescribeDBClusterParameters_593574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_593591.validator(path, query, header, formData, body)
  let scheme = call_593591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593591.url(scheme.get, call_593591.host, call_593591.base,
                         call_593591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593591, url, valid)

proc call*(call_593592: Call_GetDescribeDBClusterParameters_593574;
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
  var query_593593 = newJObject()
  add(query_593593, "Marker", newJString(Marker))
  add(query_593593, "Source", newJString(Source))
  add(query_593593, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_593593, "Action", newJString(Action))
  add(query_593593, "Version", newJString(Version))
  if Filters != nil:
    query_593593.add "Filters", Filters
  add(query_593593, "MaxRecords", newJInt(MaxRecords))
  result = call_593592.call(nil, query_593593, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_593574(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_593575, base: "/",
    url: url_GetDescribeDBClusterParameters_593576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_593631 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBClusterSnapshotAttributes_593633(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_593632(path: JsonNode;
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
  var valid_593634 = query.getOrDefault("Action")
  valid_593634 = validateParameter(valid_593634, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_593634 != nil:
    section.add "Action", valid_593634
  var valid_593635 = query.getOrDefault("Version")
  valid_593635 = validateParameter(valid_593635, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593635 != nil:
    section.add "Version", valid_593635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593636 = header.getOrDefault("X-Amz-Signature")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Signature", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Content-Sha256", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Date")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Date", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Credential")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Credential", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Security-Token")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Security-Token", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Algorithm")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Algorithm", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-SignedHeaders", valid_593642
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_593643 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593643 = validateParameter(valid_593643, JString, required = true,
                                 default = nil)
  if valid_593643 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593643
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593644: Call_PostDescribeDBClusterSnapshotAttributes_593631;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_593644.validator(path, query, header, formData, body)
  let scheme = call_593644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593644.url(scheme.get, call_593644.host, call_593644.base,
                         call_593644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593644, url, valid)

proc call*(call_593645: Call_PostDescribeDBClusterSnapshotAttributes_593631;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593646 = newJObject()
  var formData_593647 = newJObject()
  add(formData_593647, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593646, "Action", newJString(Action))
  add(query_593646, "Version", newJString(Version))
  result = call_593645.call(nil, query_593646, nil, formData_593647, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_593631(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_593632, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_593633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_593615 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBClusterSnapshotAttributes_593617(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_593616(path: JsonNode;
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
  var valid_593618 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593618 = validateParameter(valid_593618, JString, required = true,
                                 default = nil)
  if valid_593618 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593618
  var valid_593619 = query.getOrDefault("Action")
  valid_593619 = validateParameter(valid_593619, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_593619 != nil:
    section.add "Action", valid_593619
  var valid_593620 = query.getOrDefault("Version")
  valid_593620 = validateParameter(valid_593620, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593620 != nil:
    section.add "Version", valid_593620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593621 = header.getOrDefault("X-Amz-Signature")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Signature", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Content-Sha256", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Date")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Date", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Credential")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Credential", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Security-Token")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Security-Token", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Algorithm")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Algorithm", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-SignedHeaders", valid_593627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593628: Call_GetDescribeDBClusterSnapshotAttributes_593615;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_593628.validator(path, query, header, formData, body)
  let scheme = call_593628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593628.url(scheme.get, call_593628.host, call_593628.base,
                         call_593628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593628, url, valid)

proc call*(call_593629: Call_GetDescribeDBClusterSnapshotAttributes_593615;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593630 = newJObject()
  add(query_593630, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593630, "Action", newJString(Action))
  add(query_593630, "Version", newJString(Version))
  result = call_593629.call(nil, query_593630, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_593615(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_593616, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_593617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_593671 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBClusterSnapshots_593673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_593672(path: JsonNode;
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
  var valid_593674 = query.getOrDefault("Action")
  valid_593674 = validateParameter(valid_593674, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_593674 != nil:
    section.add "Action", valid_593674
  var valid_593675 = query.getOrDefault("Version")
  valid_593675 = validateParameter(valid_593675, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593675 != nil:
    section.add "Version", valid_593675
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593676 = header.getOrDefault("X-Amz-Signature")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Signature", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Content-Sha256", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Date")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Date", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Credential")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Credential", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-Security-Token")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Security-Token", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Algorithm")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Algorithm", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-SignedHeaders", valid_593682
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
  var valid_593683 = formData.getOrDefault("SnapshotType")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "SnapshotType", valid_593683
  var valid_593684 = formData.getOrDefault("MaxRecords")
  valid_593684 = validateParameter(valid_593684, JInt, required = false, default = nil)
  if valid_593684 != nil:
    section.add "MaxRecords", valid_593684
  var valid_593685 = formData.getOrDefault("IncludePublic")
  valid_593685 = validateParameter(valid_593685, JBool, required = false, default = nil)
  if valid_593685 != nil:
    section.add "IncludePublic", valid_593685
  var valid_593686 = formData.getOrDefault("Marker")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "Marker", valid_593686
  var valid_593687 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593687
  var valid_593688 = formData.getOrDefault("IncludeShared")
  valid_593688 = validateParameter(valid_593688, JBool, required = false, default = nil)
  if valid_593688 != nil:
    section.add "IncludeShared", valid_593688
  var valid_593689 = formData.getOrDefault("Filters")
  valid_593689 = validateParameter(valid_593689, JArray, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "Filters", valid_593689
  var valid_593690 = formData.getOrDefault("DBClusterIdentifier")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "DBClusterIdentifier", valid_593690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593691: Call_PostDescribeDBClusterSnapshots_593671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_593691.validator(path, query, header, formData, body)
  let scheme = call_593691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593691.url(scheme.get, call_593691.host, call_593691.base,
                         call_593691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593691, url, valid)

proc call*(call_593692: Call_PostDescribeDBClusterSnapshots_593671;
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
  var query_593693 = newJObject()
  var formData_593694 = newJObject()
  add(formData_593694, "SnapshotType", newJString(SnapshotType))
  add(formData_593694, "MaxRecords", newJInt(MaxRecords))
  add(formData_593694, "IncludePublic", newJBool(IncludePublic))
  add(formData_593694, "Marker", newJString(Marker))
  add(formData_593694, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_593694, "IncludeShared", newJBool(IncludeShared))
  add(query_593693, "Action", newJString(Action))
  if Filters != nil:
    formData_593694.add "Filters", Filters
  add(query_593693, "Version", newJString(Version))
  add(formData_593694, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_593692.call(nil, query_593693, nil, formData_593694, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_593671(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_593672, base: "/",
    url: url_PostDescribeDBClusterSnapshots_593673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_593648 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBClusterSnapshots_593650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_593649(path: JsonNode; query: JsonNode;
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
  var valid_593651 = query.getOrDefault("Marker")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "Marker", valid_593651
  var valid_593652 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_593652
  var valid_593653 = query.getOrDefault("DBClusterIdentifier")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "DBClusterIdentifier", valid_593653
  var valid_593654 = query.getOrDefault("SnapshotType")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "SnapshotType", valid_593654
  var valid_593655 = query.getOrDefault("IncludePublic")
  valid_593655 = validateParameter(valid_593655, JBool, required = false, default = nil)
  if valid_593655 != nil:
    section.add "IncludePublic", valid_593655
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593656 = query.getOrDefault("Action")
  valid_593656 = validateParameter(valid_593656, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_593656 != nil:
    section.add "Action", valid_593656
  var valid_593657 = query.getOrDefault("IncludeShared")
  valid_593657 = validateParameter(valid_593657, JBool, required = false, default = nil)
  if valid_593657 != nil:
    section.add "IncludeShared", valid_593657
  var valid_593658 = query.getOrDefault("Version")
  valid_593658 = validateParameter(valid_593658, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593658 != nil:
    section.add "Version", valid_593658
  var valid_593659 = query.getOrDefault("Filters")
  valid_593659 = validateParameter(valid_593659, JArray, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "Filters", valid_593659
  var valid_593660 = query.getOrDefault("MaxRecords")
  valid_593660 = validateParameter(valid_593660, JInt, required = false, default = nil)
  if valid_593660 != nil:
    section.add "MaxRecords", valid_593660
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593661 = header.getOrDefault("X-Amz-Signature")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Signature", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Content-Sha256", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-Date")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-Date", valid_593663
  var valid_593664 = header.getOrDefault("X-Amz-Credential")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Credential", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-Security-Token")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Security-Token", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Algorithm")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Algorithm", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-SignedHeaders", valid_593667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593668: Call_GetDescribeDBClusterSnapshots_593648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_593668.validator(path, query, header, formData, body)
  let scheme = call_593668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593668.url(scheme.get, call_593668.host, call_593668.base,
                         call_593668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593668, url, valid)

proc call*(call_593669: Call_GetDescribeDBClusterSnapshots_593648;
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
  var query_593670 = newJObject()
  add(query_593670, "Marker", newJString(Marker))
  add(query_593670, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_593670, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593670, "SnapshotType", newJString(SnapshotType))
  add(query_593670, "IncludePublic", newJBool(IncludePublic))
  add(query_593670, "Action", newJString(Action))
  add(query_593670, "IncludeShared", newJBool(IncludeShared))
  add(query_593670, "Version", newJString(Version))
  if Filters != nil:
    query_593670.add "Filters", Filters
  add(query_593670, "MaxRecords", newJInt(MaxRecords))
  result = call_593669.call(nil, query_593670, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_593648(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_593649, base: "/",
    url: url_GetDescribeDBClusterSnapshots_593650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_593714 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBClusters_593716(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusters_593715(path: JsonNode; query: JsonNode;
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
  var valid_593717 = query.getOrDefault("Action")
  valid_593717 = validateParameter(valid_593717, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_593717 != nil:
    section.add "Action", valid_593717
  var valid_593718 = query.getOrDefault("Version")
  valid_593718 = validateParameter(valid_593718, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593718 != nil:
    section.add "Version", valid_593718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593719 = header.getOrDefault("X-Amz-Signature")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "X-Amz-Signature", valid_593719
  var valid_593720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Content-Sha256", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-Date")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-Date", valid_593721
  var valid_593722 = header.getOrDefault("X-Amz-Credential")
  valid_593722 = validateParameter(valid_593722, JString, required = false,
                                 default = nil)
  if valid_593722 != nil:
    section.add "X-Amz-Credential", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Security-Token")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Security-Token", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Algorithm")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Algorithm", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-SignedHeaders", valid_593725
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
  var valid_593726 = formData.getOrDefault("MaxRecords")
  valid_593726 = validateParameter(valid_593726, JInt, required = false, default = nil)
  if valid_593726 != nil:
    section.add "MaxRecords", valid_593726
  var valid_593727 = formData.getOrDefault("Marker")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "Marker", valid_593727
  var valid_593728 = formData.getOrDefault("Filters")
  valid_593728 = validateParameter(valid_593728, JArray, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "Filters", valid_593728
  var valid_593729 = formData.getOrDefault("DBClusterIdentifier")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "DBClusterIdentifier", valid_593729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593730: Call_PostDescribeDBClusters_593714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_593730.validator(path, query, header, formData, body)
  let scheme = call_593730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593730.url(scheme.get, call_593730.host, call_593730.base,
                         call_593730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593730, url, valid)

proc call*(call_593731: Call_PostDescribeDBClusters_593714; MaxRecords: int = 0;
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
  var query_593732 = newJObject()
  var formData_593733 = newJObject()
  add(formData_593733, "MaxRecords", newJInt(MaxRecords))
  add(formData_593733, "Marker", newJString(Marker))
  add(query_593732, "Action", newJString(Action))
  if Filters != nil:
    formData_593733.add "Filters", Filters
  add(query_593732, "Version", newJString(Version))
  add(formData_593733, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_593731.call(nil, query_593732, nil, formData_593733, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_593714(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_593715, base: "/",
    url: url_PostDescribeDBClusters_593716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_593695 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBClusters_593697(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusters_593696(path: JsonNode; query: JsonNode;
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
  var valid_593698 = query.getOrDefault("Marker")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "Marker", valid_593698
  var valid_593699 = query.getOrDefault("DBClusterIdentifier")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "DBClusterIdentifier", valid_593699
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593700 = query.getOrDefault("Action")
  valid_593700 = validateParameter(valid_593700, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_593700 != nil:
    section.add "Action", valid_593700
  var valid_593701 = query.getOrDefault("Version")
  valid_593701 = validateParameter(valid_593701, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593701 != nil:
    section.add "Version", valid_593701
  var valid_593702 = query.getOrDefault("Filters")
  valid_593702 = validateParameter(valid_593702, JArray, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "Filters", valid_593702
  var valid_593703 = query.getOrDefault("MaxRecords")
  valid_593703 = validateParameter(valid_593703, JInt, required = false, default = nil)
  if valid_593703 != nil:
    section.add "MaxRecords", valid_593703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593704 = header.getOrDefault("X-Amz-Signature")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "X-Amz-Signature", valid_593704
  var valid_593705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Content-Sha256", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-Date")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Date", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Credential")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Credential", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Security-Token")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Security-Token", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Algorithm")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Algorithm", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-SignedHeaders", valid_593710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593711: Call_GetDescribeDBClusters_593695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_593711.validator(path, query, header, formData, body)
  let scheme = call_593711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593711.url(scheme.get, call_593711.host, call_593711.base,
                         call_593711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593711, url, valid)

proc call*(call_593712: Call_GetDescribeDBClusters_593695; Marker: string = "";
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
  var query_593713 = newJObject()
  add(query_593713, "Marker", newJString(Marker))
  add(query_593713, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_593713, "Action", newJString(Action))
  add(query_593713, "Version", newJString(Version))
  if Filters != nil:
    query_593713.add "Filters", Filters
  add(query_593713, "MaxRecords", newJInt(MaxRecords))
  result = call_593712.call(nil, query_593713, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_593695(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_593696, base: "/",
    url: url_GetDescribeDBClusters_593697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_593758 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBEngineVersions_593760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_593759(path: JsonNode; query: JsonNode;
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
  var valid_593761 = query.getOrDefault("Action")
  valid_593761 = validateParameter(valid_593761, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593761 != nil:
    section.add "Action", valid_593761
  var valid_593762 = query.getOrDefault("Version")
  valid_593762 = validateParameter(valid_593762, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593762 != nil:
    section.add "Version", valid_593762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593763 = header.getOrDefault("X-Amz-Signature")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Signature", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Content-Sha256", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-Date")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Date", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-Credential")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-Credential", valid_593766
  var valid_593767 = header.getOrDefault("X-Amz-Security-Token")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Security-Token", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Algorithm")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Algorithm", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-SignedHeaders", valid_593769
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
  var valid_593770 = formData.getOrDefault("DefaultOnly")
  valid_593770 = validateParameter(valid_593770, JBool, required = false, default = nil)
  if valid_593770 != nil:
    section.add "DefaultOnly", valid_593770
  var valid_593771 = formData.getOrDefault("MaxRecords")
  valid_593771 = validateParameter(valid_593771, JInt, required = false, default = nil)
  if valid_593771 != nil:
    section.add "MaxRecords", valid_593771
  var valid_593772 = formData.getOrDefault("EngineVersion")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "EngineVersion", valid_593772
  var valid_593773 = formData.getOrDefault("Marker")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "Marker", valid_593773
  var valid_593774 = formData.getOrDefault("Engine")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "Engine", valid_593774
  var valid_593775 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_593775 = validateParameter(valid_593775, JBool, required = false, default = nil)
  if valid_593775 != nil:
    section.add "ListSupportedCharacterSets", valid_593775
  var valid_593776 = formData.getOrDefault("ListSupportedTimezones")
  valid_593776 = validateParameter(valid_593776, JBool, required = false, default = nil)
  if valid_593776 != nil:
    section.add "ListSupportedTimezones", valid_593776
  var valid_593777 = formData.getOrDefault("Filters")
  valid_593777 = validateParameter(valid_593777, JArray, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "Filters", valid_593777
  var valid_593778 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "DBParameterGroupFamily", valid_593778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593779: Call_PostDescribeDBEngineVersions_593758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_593779.validator(path, query, header, formData, body)
  let scheme = call_593779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593779.url(scheme.get, call_593779.host, call_593779.base,
                         call_593779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593779, url, valid)

proc call*(call_593780: Call_PostDescribeDBEngineVersions_593758;
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
  var query_593781 = newJObject()
  var formData_593782 = newJObject()
  add(formData_593782, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_593782, "MaxRecords", newJInt(MaxRecords))
  add(formData_593782, "EngineVersion", newJString(EngineVersion))
  add(formData_593782, "Marker", newJString(Marker))
  add(formData_593782, "Engine", newJString(Engine))
  add(formData_593782, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593781, "Action", newJString(Action))
  add(formData_593782, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  if Filters != nil:
    formData_593782.add "Filters", Filters
  add(query_593781, "Version", newJString(Version))
  add(formData_593782, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593780.call(nil, query_593781, nil, formData_593782, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_593758(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_593759, base: "/",
    url: url_PostDescribeDBEngineVersions_593760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_593734 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBEngineVersions_593736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_593735(path: JsonNode; query: JsonNode;
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
  var valid_593737 = query.getOrDefault("Marker")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "Marker", valid_593737
  var valid_593738 = query.getOrDefault("ListSupportedTimezones")
  valid_593738 = validateParameter(valid_593738, JBool, required = false, default = nil)
  if valid_593738 != nil:
    section.add "ListSupportedTimezones", valid_593738
  var valid_593739 = query.getOrDefault("DBParameterGroupFamily")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "DBParameterGroupFamily", valid_593739
  var valid_593740 = query.getOrDefault("Engine")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "Engine", valid_593740
  var valid_593741 = query.getOrDefault("EngineVersion")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "EngineVersion", valid_593741
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593742 = query.getOrDefault("Action")
  valid_593742 = validateParameter(valid_593742, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593742 != nil:
    section.add "Action", valid_593742
  var valid_593743 = query.getOrDefault("ListSupportedCharacterSets")
  valid_593743 = validateParameter(valid_593743, JBool, required = false, default = nil)
  if valid_593743 != nil:
    section.add "ListSupportedCharacterSets", valid_593743
  var valid_593744 = query.getOrDefault("Version")
  valid_593744 = validateParameter(valid_593744, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593744 != nil:
    section.add "Version", valid_593744
  var valid_593745 = query.getOrDefault("Filters")
  valid_593745 = validateParameter(valid_593745, JArray, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "Filters", valid_593745
  var valid_593746 = query.getOrDefault("MaxRecords")
  valid_593746 = validateParameter(valid_593746, JInt, required = false, default = nil)
  if valid_593746 != nil:
    section.add "MaxRecords", valid_593746
  var valid_593747 = query.getOrDefault("DefaultOnly")
  valid_593747 = validateParameter(valid_593747, JBool, required = false, default = nil)
  if valid_593747 != nil:
    section.add "DefaultOnly", valid_593747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593748 = header.getOrDefault("X-Amz-Signature")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Signature", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Content-Sha256", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Date")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Date", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-Credential")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-Credential", valid_593751
  var valid_593752 = header.getOrDefault("X-Amz-Security-Token")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "X-Amz-Security-Token", valid_593752
  var valid_593753 = header.getOrDefault("X-Amz-Algorithm")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "X-Amz-Algorithm", valid_593753
  var valid_593754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "X-Amz-SignedHeaders", valid_593754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593755: Call_GetDescribeDBEngineVersions_593734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_593755.validator(path, query, header, formData, body)
  let scheme = call_593755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593755.url(scheme.get, call_593755.host, call_593755.base,
                         call_593755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593755, url, valid)

proc call*(call_593756: Call_GetDescribeDBEngineVersions_593734;
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
  var query_593757 = newJObject()
  add(query_593757, "Marker", newJString(Marker))
  add(query_593757, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_593757, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593757, "Engine", newJString(Engine))
  add(query_593757, "EngineVersion", newJString(EngineVersion))
  add(query_593757, "Action", newJString(Action))
  add(query_593757, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593757, "Version", newJString(Version))
  if Filters != nil:
    query_593757.add "Filters", Filters
  add(query_593757, "MaxRecords", newJInt(MaxRecords))
  add(query_593757, "DefaultOnly", newJBool(DefaultOnly))
  result = call_593756.call(nil, query_593757, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_593734(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_593735, base: "/",
    url: url_GetDescribeDBEngineVersions_593736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_593802 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBInstances_593804(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_593803(path: JsonNode; query: JsonNode;
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
  var valid_593805 = query.getOrDefault("Action")
  valid_593805 = validateParameter(valid_593805, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593805 != nil:
    section.add "Action", valid_593805
  var valid_593806 = query.getOrDefault("Version")
  valid_593806 = validateParameter(valid_593806, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593806 != nil:
    section.add "Version", valid_593806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593807 = header.getOrDefault("X-Amz-Signature")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Signature", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Content-Sha256", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Date")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Date", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-Credential")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Credential", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Security-Token")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Security-Token", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Algorithm")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Algorithm", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-SignedHeaders", valid_593813
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
  var valid_593814 = formData.getOrDefault("MaxRecords")
  valid_593814 = validateParameter(valid_593814, JInt, required = false, default = nil)
  if valid_593814 != nil:
    section.add "MaxRecords", valid_593814
  var valid_593815 = formData.getOrDefault("Marker")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "Marker", valid_593815
  var valid_593816 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "DBInstanceIdentifier", valid_593816
  var valid_593817 = formData.getOrDefault("Filters")
  valid_593817 = validateParameter(valid_593817, JArray, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "Filters", valid_593817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593818: Call_PostDescribeDBInstances_593802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_593818.validator(path, query, header, formData, body)
  let scheme = call_593818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593818.url(scheme.get, call_593818.host, call_593818.base,
                         call_593818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593818, url, valid)

proc call*(call_593819: Call_PostDescribeDBInstances_593802; MaxRecords: int = 0;
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
  var query_593820 = newJObject()
  var formData_593821 = newJObject()
  add(formData_593821, "MaxRecords", newJInt(MaxRecords))
  add(formData_593821, "Marker", newJString(Marker))
  add(formData_593821, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593820, "Action", newJString(Action))
  if Filters != nil:
    formData_593821.add "Filters", Filters
  add(query_593820, "Version", newJString(Version))
  result = call_593819.call(nil, query_593820, nil, formData_593821, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_593802(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_593803, base: "/",
    url: url_PostDescribeDBInstances_593804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_593783 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBInstances_593785(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_593784(path: JsonNode; query: JsonNode;
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
  var valid_593786 = query.getOrDefault("Marker")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "Marker", valid_593786
  var valid_593787 = query.getOrDefault("DBInstanceIdentifier")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "DBInstanceIdentifier", valid_593787
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593788 = query.getOrDefault("Action")
  valid_593788 = validateParameter(valid_593788, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593788 != nil:
    section.add "Action", valid_593788
  var valid_593789 = query.getOrDefault("Version")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593789 != nil:
    section.add "Version", valid_593789
  var valid_593790 = query.getOrDefault("Filters")
  valid_593790 = validateParameter(valid_593790, JArray, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "Filters", valid_593790
  var valid_593791 = query.getOrDefault("MaxRecords")
  valid_593791 = validateParameter(valid_593791, JInt, required = false, default = nil)
  if valid_593791 != nil:
    section.add "MaxRecords", valid_593791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593792 = header.getOrDefault("X-Amz-Signature")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "X-Amz-Signature", valid_593792
  var valid_593793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593793 = validateParameter(valid_593793, JString, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "X-Amz-Content-Sha256", valid_593793
  var valid_593794 = header.getOrDefault("X-Amz-Date")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "X-Amz-Date", valid_593794
  var valid_593795 = header.getOrDefault("X-Amz-Credential")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Credential", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Security-Token")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Security-Token", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Algorithm")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Algorithm", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-SignedHeaders", valid_593798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593799: Call_GetDescribeDBInstances_593783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_593799.validator(path, query, header, formData, body)
  let scheme = call_593799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593799.url(scheme.get, call_593799.host, call_593799.base,
                         call_593799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593799, url, valid)

proc call*(call_593800: Call_GetDescribeDBInstances_593783; Marker: string = "";
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
  var query_593801 = newJObject()
  add(query_593801, "Marker", newJString(Marker))
  add(query_593801, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593801, "Action", newJString(Action))
  add(query_593801, "Version", newJString(Version))
  if Filters != nil:
    query_593801.add "Filters", Filters
  add(query_593801, "MaxRecords", newJInt(MaxRecords))
  result = call_593800.call(nil, query_593801, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_593783(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_593784, base: "/",
    url: url_GetDescribeDBInstances_593785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_593841 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSubnetGroups_593843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_593842(path: JsonNode; query: JsonNode;
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
  var valid_593844 = query.getOrDefault("Action")
  valid_593844 = validateParameter(valid_593844, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593844 != nil:
    section.add "Action", valid_593844
  var valid_593845 = query.getOrDefault("Version")
  valid_593845 = validateParameter(valid_593845, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593845 != nil:
    section.add "Version", valid_593845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593846 = header.getOrDefault("X-Amz-Signature")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Signature", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Content-Sha256", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Date")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Date", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Credential")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Credential", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Security-Token")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Security-Token", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Algorithm")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Algorithm", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-SignedHeaders", valid_593852
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
  var valid_593853 = formData.getOrDefault("MaxRecords")
  valid_593853 = validateParameter(valid_593853, JInt, required = false, default = nil)
  if valid_593853 != nil:
    section.add "MaxRecords", valid_593853
  var valid_593854 = formData.getOrDefault("Marker")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "Marker", valid_593854
  var valid_593855 = formData.getOrDefault("DBSubnetGroupName")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "DBSubnetGroupName", valid_593855
  var valid_593856 = formData.getOrDefault("Filters")
  valid_593856 = validateParameter(valid_593856, JArray, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "Filters", valid_593856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593857: Call_PostDescribeDBSubnetGroups_593841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_593857.validator(path, query, header, formData, body)
  let scheme = call_593857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593857.url(scheme.get, call_593857.host, call_593857.base,
                         call_593857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593857, url, valid)

proc call*(call_593858: Call_PostDescribeDBSubnetGroups_593841;
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
  var query_593859 = newJObject()
  var formData_593860 = newJObject()
  add(formData_593860, "MaxRecords", newJInt(MaxRecords))
  add(formData_593860, "Marker", newJString(Marker))
  add(query_593859, "Action", newJString(Action))
  add(formData_593860, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_593860.add "Filters", Filters
  add(query_593859, "Version", newJString(Version))
  result = call_593858.call(nil, query_593859, nil, formData_593860, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_593841(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_593842, base: "/",
    url: url_PostDescribeDBSubnetGroups_593843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_593822 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSubnetGroups_593824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_593823(path: JsonNode; query: JsonNode;
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
  var valid_593825 = query.getOrDefault("Marker")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "Marker", valid_593825
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593826 = query.getOrDefault("Action")
  valid_593826 = validateParameter(valid_593826, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593826 != nil:
    section.add "Action", valid_593826
  var valid_593827 = query.getOrDefault("DBSubnetGroupName")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "DBSubnetGroupName", valid_593827
  var valid_593828 = query.getOrDefault("Version")
  valid_593828 = validateParameter(valid_593828, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593828 != nil:
    section.add "Version", valid_593828
  var valid_593829 = query.getOrDefault("Filters")
  valid_593829 = validateParameter(valid_593829, JArray, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "Filters", valid_593829
  var valid_593830 = query.getOrDefault("MaxRecords")
  valid_593830 = validateParameter(valid_593830, JInt, required = false, default = nil)
  if valid_593830 != nil:
    section.add "MaxRecords", valid_593830
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593831 = header.getOrDefault("X-Amz-Signature")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-Signature", valid_593831
  var valid_593832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "X-Amz-Content-Sha256", valid_593832
  var valid_593833 = header.getOrDefault("X-Amz-Date")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-Date", valid_593833
  var valid_593834 = header.getOrDefault("X-Amz-Credential")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Credential", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Security-Token")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Security-Token", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Algorithm")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Algorithm", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-SignedHeaders", valid_593837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593838: Call_GetDescribeDBSubnetGroups_593822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_593838.validator(path, query, header, formData, body)
  let scheme = call_593838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593838.url(scheme.get, call_593838.host, call_593838.base,
                         call_593838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593838, url, valid)

proc call*(call_593839: Call_GetDescribeDBSubnetGroups_593822; Marker: string = "";
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
  var query_593840 = newJObject()
  add(query_593840, "Marker", newJString(Marker))
  add(query_593840, "Action", newJString(Action))
  add(query_593840, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593840, "Version", newJString(Version))
  if Filters != nil:
    query_593840.add "Filters", Filters
  add(query_593840, "MaxRecords", newJInt(MaxRecords))
  result = call_593839.call(nil, query_593840, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_593822(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_593823, base: "/",
    url: url_GetDescribeDBSubnetGroups_593824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_593880 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEngineDefaultClusterParameters_593882(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_593881(path: JsonNode;
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
  var valid_593883 = query.getOrDefault("Action")
  valid_593883 = validateParameter(valid_593883, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_593883 != nil:
    section.add "Action", valid_593883
  var valid_593884 = query.getOrDefault("Version")
  valid_593884 = validateParameter(valid_593884, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593884 != nil:
    section.add "Version", valid_593884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593885 = header.getOrDefault("X-Amz-Signature")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Signature", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Content-Sha256", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Date")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Date", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Credential")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Credential", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Algorithm")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Algorithm", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-SignedHeaders", valid_593891
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
  var valid_593892 = formData.getOrDefault("MaxRecords")
  valid_593892 = validateParameter(valid_593892, JInt, required = false, default = nil)
  if valid_593892 != nil:
    section.add "MaxRecords", valid_593892
  var valid_593893 = formData.getOrDefault("Marker")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "Marker", valid_593893
  var valid_593894 = formData.getOrDefault("Filters")
  valid_593894 = validateParameter(valid_593894, JArray, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "Filters", valid_593894
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593895 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593895 = validateParameter(valid_593895, JString, required = true,
                                 default = nil)
  if valid_593895 != nil:
    section.add "DBParameterGroupFamily", valid_593895
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593896: Call_PostDescribeEngineDefaultClusterParameters_593880;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_593896.validator(path, query, header, formData, body)
  let scheme = call_593896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593896.url(scheme.get, call_593896.host, call_593896.base,
                         call_593896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593896, url, valid)

proc call*(call_593897: Call_PostDescribeEngineDefaultClusterParameters_593880;
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
  var query_593898 = newJObject()
  var formData_593899 = newJObject()
  add(formData_593899, "MaxRecords", newJInt(MaxRecords))
  add(formData_593899, "Marker", newJString(Marker))
  add(query_593898, "Action", newJString(Action))
  if Filters != nil:
    formData_593899.add "Filters", Filters
  add(query_593898, "Version", newJString(Version))
  add(formData_593899, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593897.call(nil, query_593898, nil, formData_593899, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_593880(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_593881,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_593882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_593861 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEngineDefaultClusterParameters_593863(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_593862(path: JsonNode;
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
  var valid_593864 = query.getOrDefault("Marker")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "Marker", valid_593864
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593865 = query.getOrDefault("DBParameterGroupFamily")
  valid_593865 = validateParameter(valid_593865, JString, required = true,
                                 default = nil)
  if valid_593865 != nil:
    section.add "DBParameterGroupFamily", valid_593865
  var valid_593866 = query.getOrDefault("Action")
  valid_593866 = validateParameter(valid_593866, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_593866 != nil:
    section.add "Action", valid_593866
  var valid_593867 = query.getOrDefault("Version")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593867 != nil:
    section.add "Version", valid_593867
  var valid_593868 = query.getOrDefault("Filters")
  valid_593868 = validateParameter(valid_593868, JArray, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "Filters", valid_593868
  var valid_593869 = query.getOrDefault("MaxRecords")
  valid_593869 = validateParameter(valid_593869, JInt, required = false, default = nil)
  if valid_593869 != nil:
    section.add "MaxRecords", valid_593869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593870 = header.getOrDefault("X-Amz-Signature")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Signature", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Content-Sha256", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Date")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Date", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Credential")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Credential", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-Security-Token")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Security-Token", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-Algorithm")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Algorithm", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-SignedHeaders", valid_593876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593877: Call_GetDescribeEngineDefaultClusterParameters_593861;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_593877.validator(path, query, header, formData, body)
  let scheme = call_593877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593877.url(scheme.get, call_593877.host, call_593877.base,
                         call_593877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593877, url, valid)

proc call*(call_593878: Call_GetDescribeEngineDefaultClusterParameters_593861;
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
  var query_593879 = newJObject()
  add(query_593879, "Marker", newJString(Marker))
  add(query_593879, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593879, "Action", newJString(Action))
  add(query_593879, "Version", newJString(Version))
  if Filters != nil:
    query_593879.add "Filters", Filters
  add(query_593879, "MaxRecords", newJInt(MaxRecords))
  result = call_593878.call(nil, query_593879, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_593861(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_593862,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_593863,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_593917 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventCategories_593919(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_593918(path: JsonNode; query: JsonNode;
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
  var valid_593920 = query.getOrDefault("Action")
  valid_593920 = validateParameter(valid_593920, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_593920 != nil:
    section.add "Action", valid_593920
  var valid_593921 = query.getOrDefault("Version")
  valid_593921 = validateParameter(valid_593921, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593921 != nil:
    section.add "Version", valid_593921
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593922 = header.getOrDefault("X-Amz-Signature")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Signature", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Content-Sha256", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Date")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Date", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Credential")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Credential", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Security-Token")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Security-Token", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-Algorithm")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Algorithm", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-SignedHeaders", valid_593928
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_593929 = formData.getOrDefault("SourceType")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "SourceType", valid_593929
  var valid_593930 = formData.getOrDefault("Filters")
  valid_593930 = validateParameter(valid_593930, JArray, required = false,
                                 default = nil)
  if valid_593930 != nil:
    section.add "Filters", valid_593930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593931: Call_PostDescribeEventCategories_593917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_593931.validator(path, query, header, formData, body)
  let scheme = call_593931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593931.url(scheme.get, call_593931.host, call_593931.base,
                         call_593931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593931, url, valid)

proc call*(call_593932: Call_PostDescribeEventCategories_593917;
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
  var query_593933 = newJObject()
  var formData_593934 = newJObject()
  add(formData_593934, "SourceType", newJString(SourceType))
  add(query_593933, "Action", newJString(Action))
  if Filters != nil:
    formData_593934.add "Filters", Filters
  add(query_593933, "Version", newJString(Version))
  result = call_593932.call(nil, query_593933, nil, formData_593934, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_593917(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_593918, base: "/",
    url: url_PostDescribeEventCategories_593919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_593900 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventCategories_593902(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_593901(path: JsonNode; query: JsonNode;
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
  var valid_593903 = query.getOrDefault("SourceType")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "SourceType", valid_593903
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593904 = query.getOrDefault("Action")
  valid_593904 = validateParameter(valid_593904, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_593904 != nil:
    section.add "Action", valid_593904
  var valid_593905 = query.getOrDefault("Version")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593905 != nil:
    section.add "Version", valid_593905
  var valid_593906 = query.getOrDefault("Filters")
  valid_593906 = validateParameter(valid_593906, JArray, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "Filters", valid_593906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593907 = header.getOrDefault("X-Amz-Signature")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Signature", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Content-Sha256", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Date")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Date", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Credential")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Credential", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Security-Token")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Security-Token", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-Algorithm")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-Algorithm", valid_593912
  var valid_593913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "X-Amz-SignedHeaders", valid_593913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593914: Call_GetDescribeEventCategories_593900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_593914.validator(path, query, header, formData, body)
  let scheme = call_593914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593914.url(scheme.get, call_593914.host, call_593914.base,
                         call_593914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593914, url, valid)

proc call*(call_593915: Call_GetDescribeEventCategories_593900;
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
  var query_593916 = newJObject()
  add(query_593916, "SourceType", newJString(SourceType))
  add(query_593916, "Action", newJString(Action))
  add(query_593916, "Version", newJString(Version))
  if Filters != nil:
    query_593916.add "Filters", Filters
  result = call_593915.call(nil, query_593916, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_593900(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_593901, base: "/",
    url: url_GetDescribeEventCategories_593902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_593959 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEvents_593961(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_593960(path: JsonNode; query: JsonNode;
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
  var valid_593962 = query.getOrDefault("Action")
  valid_593962 = validateParameter(valid_593962, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_593962 != nil:
    section.add "Action", valid_593962
  var valid_593963 = query.getOrDefault("Version")
  valid_593963 = validateParameter(valid_593963, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593963 != nil:
    section.add "Version", valid_593963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593964 = header.getOrDefault("X-Amz-Signature")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-Signature", valid_593964
  var valid_593965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593965 = validateParameter(valid_593965, JString, required = false,
                                 default = nil)
  if valid_593965 != nil:
    section.add "X-Amz-Content-Sha256", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Date")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Date", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Credential")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Credential", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Security-Token")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Security-Token", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-Algorithm")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-Algorithm", valid_593969
  var valid_593970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "X-Amz-SignedHeaders", valid_593970
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
  var valid_593971 = formData.getOrDefault("MaxRecords")
  valid_593971 = validateParameter(valid_593971, JInt, required = false, default = nil)
  if valid_593971 != nil:
    section.add "MaxRecords", valid_593971
  var valid_593972 = formData.getOrDefault("Marker")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "Marker", valid_593972
  var valid_593973 = formData.getOrDefault("SourceIdentifier")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "SourceIdentifier", valid_593973
  var valid_593974 = formData.getOrDefault("SourceType")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_593974 != nil:
    section.add "SourceType", valid_593974
  var valid_593975 = formData.getOrDefault("Duration")
  valid_593975 = validateParameter(valid_593975, JInt, required = false, default = nil)
  if valid_593975 != nil:
    section.add "Duration", valid_593975
  var valid_593976 = formData.getOrDefault("EndTime")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "EndTime", valid_593976
  var valid_593977 = formData.getOrDefault("StartTime")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "StartTime", valid_593977
  var valid_593978 = formData.getOrDefault("EventCategories")
  valid_593978 = validateParameter(valid_593978, JArray, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "EventCategories", valid_593978
  var valid_593979 = formData.getOrDefault("Filters")
  valid_593979 = validateParameter(valid_593979, JArray, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "Filters", valid_593979
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593980: Call_PostDescribeEvents_593959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_593980.validator(path, query, header, formData, body)
  let scheme = call_593980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593980.url(scheme.get, call_593980.host, call_593980.base,
                         call_593980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593980, url, valid)

proc call*(call_593981: Call_PostDescribeEvents_593959; MaxRecords: int = 0;
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
  var query_593982 = newJObject()
  var formData_593983 = newJObject()
  add(formData_593983, "MaxRecords", newJInt(MaxRecords))
  add(formData_593983, "Marker", newJString(Marker))
  add(formData_593983, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_593983, "SourceType", newJString(SourceType))
  add(formData_593983, "Duration", newJInt(Duration))
  add(formData_593983, "EndTime", newJString(EndTime))
  add(formData_593983, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_593983.add "EventCategories", EventCategories
  add(query_593982, "Action", newJString(Action))
  if Filters != nil:
    formData_593983.add "Filters", Filters
  add(query_593982, "Version", newJString(Version))
  result = call_593981.call(nil, query_593982, nil, formData_593983, nil)

var postDescribeEvents* = Call_PostDescribeEvents_593959(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_593960, base: "/",
    url: url_PostDescribeEvents_593961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_593935 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEvents_593937(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_593936(path: JsonNode; query: JsonNode;
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
  var valid_593938 = query.getOrDefault("Marker")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "Marker", valid_593938
  var valid_593939 = query.getOrDefault("SourceType")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_593939 != nil:
    section.add "SourceType", valid_593939
  var valid_593940 = query.getOrDefault("SourceIdentifier")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "SourceIdentifier", valid_593940
  var valid_593941 = query.getOrDefault("EventCategories")
  valid_593941 = validateParameter(valid_593941, JArray, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "EventCategories", valid_593941
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593942 = query.getOrDefault("Action")
  valid_593942 = validateParameter(valid_593942, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_593942 != nil:
    section.add "Action", valid_593942
  var valid_593943 = query.getOrDefault("StartTime")
  valid_593943 = validateParameter(valid_593943, JString, required = false,
                                 default = nil)
  if valid_593943 != nil:
    section.add "StartTime", valid_593943
  var valid_593944 = query.getOrDefault("Duration")
  valid_593944 = validateParameter(valid_593944, JInt, required = false, default = nil)
  if valid_593944 != nil:
    section.add "Duration", valid_593944
  var valid_593945 = query.getOrDefault("EndTime")
  valid_593945 = validateParameter(valid_593945, JString, required = false,
                                 default = nil)
  if valid_593945 != nil:
    section.add "EndTime", valid_593945
  var valid_593946 = query.getOrDefault("Version")
  valid_593946 = validateParameter(valid_593946, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593946 != nil:
    section.add "Version", valid_593946
  var valid_593947 = query.getOrDefault("Filters")
  valid_593947 = validateParameter(valid_593947, JArray, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "Filters", valid_593947
  var valid_593948 = query.getOrDefault("MaxRecords")
  valid_593948 = validateParameter(valid_593948, JInt, required = false, default = nil)
  if valid_593948 != nil:
    section.add "MaxRecords", valid_593948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593949 = header.getOrDefault("X-Amz-Signature")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "X-Amz-Signature", valid_593949
  var valid_593950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "X-Amz-Content-Sha256", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Date")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Date", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Credential")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Credential", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Security-Token")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Security-Token", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Algorithm")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Algorithm", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-SignedHeaders", valid_593955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593956: Call_GetDescribeEvents_593935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_593956.validator(path, query, header, formData, body)
  let scheme = call_593956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593956.url(scheme.get, call_593956.host, call_593956.base,
                         call_593956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593956, url, valid)

proc call*(call_593957: Call_GetDescribeEvents_593935; Marker: string = "";
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
  var query_593958 = newJObject()
  add(query_593958, "Marker", newJString(Marker))
  add(query_593958, "SourceType", newJString(SourceType))
  add(query_593958, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_593958.add "EventCategories", EventCategories
  add(query_593958, "Action", newJString(Action))
  add(query_593958, "StartTime", newJString(StartTime))
  add(query_593958, "Duration", newJInt(Duration))
  add(query_593958, "EndTime", newJString(EndTime))
  add(query_593958, "Version", newJString(Version))
  if Filters != nil:
    query_593958.add "Filters", Filters
  add(query_593958, "MaxRecords", newJInt(MaxRecords))
  result = call_593957.call(nil, query_593958, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_593935(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_593936,
    base: "/", url: url_GetDescribeEvents_593937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_594007 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOrderableDBInstanceOptions_594009(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_594008(path: JsonNode;
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
  var valid_594010 = query.getOrDefault("Action")
  valid_594010 = validateParameter(valid_594010, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594010 != nil:
    section.add "Action", valid_594010
  var valid_594011 = query.getOrDefault("Version")
  valid_594011 = validateParameter(valid_594011, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594011 != nil:
    section.add "Version", valid_594011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594012 = header.getOrDefault("X-Amz-Signature")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Signature", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Content-Sha256", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-Date")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-Date", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Credential")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Credential", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Security-Token")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Security-Token", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Algorithm")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Algorithm", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-SignedHeaders", valid_594018
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
  var valid_594019 = formData.getOrDefault("DBInstanceClass")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "DBInstanceClass", valid_594019
  var valid_594020 = formData.getOrDefault("MaxRecords")
  valid_594020 = validateParameter(valid_594020, JInt, required = false, default = nil)
  if valid_594020 != nil:
    section.add "MaxRecords", valid_594020
  var valid_594021 = formData.getOrDefault("EngineVersion")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "EngineVersion", valid_594021
  var valid_594022 = formData.getOrDefault("Marker")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "Marker", valid_594022
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594023 = formData.getOrDefault("Engine")
  valid_594023 = validateParameter(valid_594023, JString, required = true,
                                 default = nil)
  if valid_594023 != nil:
    section.add "Engine", valid_594023
  var valid_594024 = formData.getOrDefault("Vpc")
  valid_594024 = validateParameter(valid_594024, JBool, required = false, default = nil)
  if valid_594024 != nil:
    section.add "Vpc", valid_594024
  var valid_594025 = formData.getOrDefault("LicenseModel")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "LicenseModel", valid_594025
  var valid_594026 = formData.getOrDefault("Filters")
  valid_594026 = validateParameter(valid_594026, JArray, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "Filters", valid_594026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594027: Call_PostDescribeOrderableDBInstanceOptions_594007;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_594027.validator(path, query, header, formData, body)
  let scheme = call_594027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594027.url(scheme.get, call_594027.host, call_594027.base,
                         call_594027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594027, url, valid)

proc call*(call_594028: Call_PostDescribeOrderableDBInstanceOptions_594007;
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
  var query_594029 = newJObject()
  var formData_594030 = newJObject()
  add(formData_594030, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594030, "MaxRecords", newJInt(MaxRecords))
  add(formData_594030, "EngineVersion", newJString(EngineVersion))
  add(formData_594030, "Marker", newJString(Marker))
  add(formData_594030, "Engine", newJString(Engine))
  add(formData_594030, "Vpc", newJBool(Vpc))
  add(query_594029, "Action", newJString(Action))
  add(formData_594030, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_594030.add "Filters", Filters
  add(query_594029, "Version", newJString(Version))
  result = call_594028.call(nil, query_594029, nil, formData_594030, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_594007(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_594008, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_594009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_593984 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOrderableDBInstanceOptions_593986(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_593985(path: JsonNode;
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
  var valid_593987 = query.getOrDefault("Marker")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "Marker", valid_593987
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_593988 = query.getOrDefault("Engine")
  valid_593988 = validateParameter(valid_593988, JString, required = true,
                                 default = nil)
  if valid_593988 != nil:
    section.add "Engine", valid_593988
  var valid_593989 = query.getOrDefault("LicenseModel")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "LicenseModel", valid_593989
  var valid_593990 = query.getOrDefault("Vpc")
  valid_593990 = validateParameter(valid_593990, JBool, required = false, default = nil)
  if valid_593990 != nil:
    section.add "Vpc", valid_593990
  var valid_593991 = query.getOrDefault("EngineVersion")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "EngineVersion", valid_593991
  var valid_593992 = query.getOrDefault("Action")
  valid_593992 = validateParameter(valid_593992, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_593992 != nil:
    section.add "Action", valid_593992
  var valid_593993 = query.getOrDefault("Version")
  valid_593993 = validateParameter(valid_593993, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593993 != nil:
    section.add "Version", valid_593993
  var valid_593994 = query.getOrDefault("DBInstanceClass")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "DBInstanceClass", valid_593994
  var valid_593995 = query.getOrDefault("Filters")
  valid_593995 = validateParameter(valid_593995, JArray, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "Filters", valid_593995
  var valid_593996 = query.getOrDefault("MaxRecords")
  valid_593996 = validateParameter(valid_593996, JInt, required = false, default = nil)
  if valid_593996 != nil:
    section.add "MaxRecords", valid_593996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593997 = header.getOrDefault("X-Amz-Signature")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "X-Amz-Signature", valid_593997
  var valid_593998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "X-Amz-Content-Sha256", valid_593998
  var valid_593999 = header.getOrDefault("X-Amz-Date")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Date", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Credential")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Credential", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Security-Token")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Security-Token", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Algorithm")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Algorithm", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-SignedHeaders", valid_594003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594004: Call_GetDescribeOrderableDBInstanceOptions_593984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_594004.validator(path, query, header, formData, body)
  let scheme = call_594004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594004.url(scheme.get, call_594004.host, call_594004.base,
                         call_594004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594004, url, valid)

proc call*(call_594005: Call_GetDescribeOrderableDBInstanceOptions_593984;
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
  var query_594006 = newJObject()
  add(query_594006, "Marker", newJString(Marker))
  add(query_594006, "Engine", newJString(Engine))
  add(query_594006, "LicenseModel", newJString(LicenseModel))
  add(query_594006, "Vpc", newJBool(Vpc))
  add(query_594006, "EngineVersion", newJString(EngineVersion))
  add(query_594006, "Action", newJString(Action))
  add(query_594006, "Version", newJString(Version))
  add(query_594006, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594006.add "Filters", Filters
  add(query_594006, "MaxRecords", newJInt(MaxRecords))
  result = call_594005.call(nil, query_594006, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_593984(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_593985, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_593986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_594050 = ref object of OpenApiRestCall_592348
proc url_PostDescribePendingMaintenanceActions_594052(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_594051(path: JsonNode;
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
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("Version")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594054 != nil:
    section.add "Version", valid_594054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Content-Sha256", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Date")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Date", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Credential")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Credential", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Security-Token")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Security-Token", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Algorithm")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Algorithm", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-SignedHeaders", valid_594061
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
  var valid_594062 = formData.getOrDefault("MaxRecords")
  valid_594062 = validateParameter(valid_594062, JInt, required = false, default = nil)
  if valid_594062 != nil:
    section.add "MaxRecords", valid_594062
  var valid_594063 = formData.getOrDefault("Marker")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "Marker", valid_594063
  var valid_594064 = formData.getOrDefault("ResourceIdentifier")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "ResourceIdentifier", valid_594064
  var valid_594065 = formData.getOrDefault("Filters")
  valid_594065 = validateParameter(valid_594065, JArray, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "Filters", valid_594065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594066: Call_PostDescribePendingMaintenanceActions_594050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_594066.validator(path, query, header, formData, body)
  let scheme = call_594066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594066.url(scheme.get, call_594066.host, call_594066.base,
                         call_594066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594066, url, valid)

proc call*(call_594067: Call_PostDescribePendingMaintenanceActions_594050;
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
  var query_594068 = newJObject()
  var formData_594069 = newJObject()
  add(formData_594069, "MaxRecords", newJInt(MaxRecords))
  add(formData_594069, "Marker", newJString(Marker))
  add(formData_594069, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_594068, "Action", newJString(Action))
  if Filters != nil:
    formData_594069.add "Filters", Filters
  add(query_594068, "Version", newJString(Version))
  result = call_594067.call(nil, query_594068, nil, formData_594069, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_594050(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_594051, base: "/",
    url: url_PostDescribePendingMaintenanceActions_594052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_594031 = ref object of OpenApiRestCall_592348
proc url_GetDescribePendingMaintenanceActions_594033(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_594032(path: JsonNode;
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
  var valid_594034 = query.getOrDefault("ResourceIdentifier")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "ResourceIdentifier", valid_594034
  var valid_594035 = query.getOrDefault("Marker")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "Marker", valid_594035
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594036 = query.getOrDefault("Action")
  valid_594036 = validateParameter(valid_594036, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_594036 != nil:
    section.add "Action", valid_594036
  var valid_594037 = query.getOrDefault("Version")
  valid_594037 = validateParameter(valid_594037, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594037 != nil:
    section.add "Version", valid_594037
  var valid_594038 = query.getOrDefault("Filters")
  valid_594038 = validateParameter(valid_594038, JArray, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "Filters", valid_594038
  var valid_594039 = query.getOrDefault("MaxRecords")
  valid_594039 = validateParameter(valid_594039, JInt, required = false, default = nil)
  if valid_594039 != nil:
    section.add "MaxRecords", valid_594039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594040 = header.getOrDefault("X-Amz-Signature")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Signature", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Content-Sha256", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Date")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Date", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Credential")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Credential", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Security-Token")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Security-Token", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Algorithm")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Algorithm", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-SignedHeaders", valid_594046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594047: Call_GetDescribePendingMaintenanceActions_594031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_594047.validator(path, query, header, formData, body)
  let scheme = call_594047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594047.url(scheme.get, call_594047.host, call_594047.base,
                         call_594047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594047, url, valid)

proc call*(call_594048: Call_GetDescribePendingMaintenanceActions_594031;
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
  var query_594049 = newJObject()
  add(query_594049, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_594049, "Marker", newJString(Marker))
  add(query_594049, "Action", newJString(Action))
  add(query_594049, "Version", newJString(Version))
  if Filters != nil:
    query_594049.add "Filters", Filters
  add(query_594049, "MaxRecords", newJInt(MaxRecords))
  result = call_594048.call(nil, query_594049, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_594031(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_594032, base: "/",
    url: url_GetDescribePendingMaintenanceActions_594033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_594087 = ref object of OpenApiRestCall_592348
proc url_PostFailoverDBCluster_594089(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostFailoverDBCluster_594088(path: JsonNode; query: JsonNode;
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
  var valid_594090 = query.getOrDefault("Action")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_594090 != nil:
    section.add "Action", valid_594090
  var valid_594091 = query.getOrDefault("Version")
  valid_594091 = validateParameter(valid_594091, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594091 != nil:
    section.add "Version", valid_594091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594092 = header.getOrDefault("X-Amz-Signature")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Signature", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Content-Sha256", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Date")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Date", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Credential")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Credential", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Security-Token")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Security-Token", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Algorithm")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Algorithm", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_594099 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594099
  var valid_594100 = formData.getOrDefault("DBClusterIdentifier")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "DBClusterIdentifier", valid_594100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_PostFailoverDBCluster_594087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_PostFailoverDBCluster_594087;
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
  var query_594103 = newJObject()
  var formData_594104 = newJObject()
  add(query_594103, "Action", newJString(Action))
  add(formData_594104, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594103, "Version", newJString(Version))
  add(formData_594104, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_594102.call(nil, query_594103, nil, formData_594104, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_594087(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_594088, base: "/",
    url: url_PostFailoverDBCluster_594089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_594070 = ref object of OpenApiRestCall_592348
proc url_GetFailoverDBCluster_594072(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFailoverDBCluster_594071(path: JsonNode; query: JsonNode;
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
  var valid_594073 = query.getOrDefault("DBClusterIdentifier")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "DBClusterIdentifier", valid_594073
  var valid_594074 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594074
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594075 = query.getOrDefault("Action")
  valid_594075 = validateParameter(valid_594075, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_594075 != nil:
    section.add "Action", valid_594075
  var valid_594076 = query.getOrDefault("Version")
  valid_594076 = validateParameter(valid_594076, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594076 != nil:
    section.add "Version", valid_594076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594077 = header.getOrDefault("X-Amz-Signature")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Signature", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Content-Sha256", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Date")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Date", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Credential")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Credential", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Security-Token")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Security-Token", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Algorithm")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Algorithm", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594084: Call_GetFailoverDBCluster_594070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_594084.validator(path, query, header, formData, body)
  let scheme = call_594084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594084.url(scheme.get, call_594084.host, call_594084.base,
                         call_594084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594084, url, valid)

proc call*(call_594085: Call_GetFailoverDBCluster_594070;
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
  var query_594086 = newJObject()
  add(query_594086, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594086, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594086, "Action", newJString(Action))
  add(query_594086, "Version", newJString(Version))
  result = call_594085.call(nil, query_594086, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_594070(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_594071, base: "/",
    url: url_GetFailoverDBCluster_594072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594122 = ref object of OpenApiRestCall_592348
proc url_PostListTagsForResource_594124(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594123(path: JsonNode; query: JsonNode;
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
  var valid_594125 = query.getOrDefault("Action")
  valid_594125 = validateParameter(valid_594125, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594125 != nil:
    section.add "Action", valid_594125
  var valid_594126 = query.getOrDefault("Version")
  valid_594126 = validateParameter(valid_594126, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594126 != nil:
    section.add "Version", valid_594126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Content-Sha256", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Date")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Date", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Credential")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Credential", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Algorithm")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Algorithm", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_594134 = formData.getOrDefault("Filters")
  valid_594134 = validateParameter(valid_594134, JArray, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "Filters", valid_594134
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_594135 = formData.getOrDefault("ResourceName")
  valid_594135 = validateParameter(valid_594135, JString, required = true,
                                 default = nil)
  if valid_594135 != nil:
    section.add "ResourceName", valid_594135
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594136: Call_PostListTagsForResource_594122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_594136.validator(path, query, header, formData, body)
  let scheme = call_594136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594136.url(scheme.get, call_594136.host, call_594136.base,
                         call_594136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594136, url, valid)

proc call*(call_594137: Call_PostListTagsForResource_594122; ResourceName: string;
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
  var query_594138 = newJObject()
  var formData_594139 = newJObject()
  add(query_594138, "Action", newJString(Action))
  if Filters != nil:
    formData_594139.add "Filters", Filters
  add(query_594138, "Version", newJString(Version))
  add(formData_594139, "ResourceName", newJString(ResourceName))
  result = call_594137.call(nil, query_594138, nil, formData_594139, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594122(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594123, base: "/",
    url: url_PostListTagsForResource_594124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594105 = ref object of OpenApiRestCall_592348
proc url_GetListTagsForResource_594107(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594106(path: JsonNode; query: JsonNode;
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
  var valid_594108 = query.getOrDefault("ResourceName")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "ResourceName", valid_594108
  var valid_594109 = query.getOrDefault("Action")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594109 != nil:
    section.add "Action", valid_594109
  var valid_594110 = query.getOrDefault("Version")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594110 != nil:
    section.add "Version", valid_594110
  var valid_594111 = query.getOrDefault("Filters")
  valid_594111 = validateParameter(valid_594111, JArray, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "Filters", valid_594111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Content-Sha256", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Date")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Date", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Algorithm")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Algorithm", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-SignedHeaders", valid_594118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594119: Call_GetListTagsForResource_594105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_594119.validator(path, query, header, formData, body)
  let scheme = call_594119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594119.url(scheme.get, call_594119.host, call_594119.base,
                         call_594119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594119, url, valid)

proc call*(call_594120: Call_GetListTagsForResource_594105; ResourceName: string;
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
  var query_594121 = newJObject()
  add(query_594121, "ResourceName", newJString(ResourceName))
  add(query_594121, "Action", newJString(Action))
  add(query_594121, "Version", newJString(Version))
  if Filters != nil:
    query_594121.add "Filters", Filters
  result = call_594120.call(nil, query_594121, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594105(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594106, base: "/",
    url: url_GetListTagsForResource_594107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_594169 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBCluster_594171(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBCluster_594170(path: JsonNode; query: JsonNode;
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
  var valid_594172 = query.getOrDefault("Action")
  valid_594172 = validateParameter(valid_594172, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_594172 != nil:
    section.add "Action", valid_594172
  var valid_594173 = query.getOrDefault("Version")
  valid_594173 = validateParameter(valid_594173, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594173 != nil:
    section.add "Version", valid_594173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594174 = header.getOrDefault("X-Amz-Signature")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Signature", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Content-Sha256", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Date")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Date", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Credential")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Credential", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Security-Token")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Security-Token", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Algorithm")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Algorithm", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-SignedHeaders", valid_594180
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
  var valid_594181 = formData.getOrDefault("Port")
  valid_594181 = validateParameter(valid_594181, JInt, required = false, default = nil)
  if valid_594181 != nil:
    section.add "Port", valid_594181
  var valid_594182 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "PreferredMaintenanceWindow", valid_594182
  var valid_594183 = formData.getOrDefault("PreferredBackupWindow")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "PreferredBackupWindow", valid_594183
  var valid_594184 = formData.getOrDefault("MasterUserPassword")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "MasterUserPassword", valid_594184
  var valid_594185 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_594185 = validateParameter(valid_594185, JArray, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_594185
  var valid_594186 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_594186 = validateParameter(valid_594186, JArray, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_594186
  var valid_594187 = formData.getOrDefault("EngineVersion")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "EngineVersion", valid_594187
  var valid_594188 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594188 = validateParameter(valid_594188, JArray, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "VpcSecurityGroupIds", valid_594188
  var valid_594189 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594189 = validateParameter(valid_594189, JInt, required = false, default = nil)
  if valid_594189 != nil:
    section.add "BackupRetentionPeriod", valid_594189
  var valid_594190 = formData.getOrDefault("ApplyImmediately")
  valid_594190 = validateParameter(valid_594190, JBool, required = false, default = nil)
  if valid_594190 != nil:
    section.add "ApplyImmediately", valid_594190
  var valid_594191 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "DBClusterParameterGroupName", valid_594191
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594192 = formData.getOrDefault("DBClusterIdentifier")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = nil)
  if valid_594192 != nil:
    section.add "DBClusterIdentifier", valid_594192
  var valid_594193 = formData.getOrDefault("DeletionProtection")
  valid_594193 = validateParameter(valid_594193, JBool, required = false, default = nil)
  if valid_594193 != nil:
    section.add "DeletionProtection", valid_594193
  var valid_594194 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "NewDBClusterIdentifier", valid_594194
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594195: Call_PostModifyDBCluster_594169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_594195.validator(path, query, header, formData, body)
  let scheme = call_594195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594195.url(scheme.get, call_594195.host, call_594195.base,
                         call_594195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594195, url, valid)

proc call*(call_594196: Call_PostModifyDBCluster_594169;
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
  var query_594197 = newJObject()
  var formData_594198 = newJObject()
  add(formData_594198, "Port", newJInt(Port))
  add(formData_594198, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594198, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594198, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_594198.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_594198.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_594198, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594198.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594198, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594198, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_594197, "Action", newJString(Action))
  add(formData_594198, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594197, "Version", newJString(Version))
  add(formData_594198, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_594198, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_594198, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  result = call_594196.call(nil, query_594197, nil, formData_594198, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_594169(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_594170, base: "/",
    url: url_PostModifyDBCluster_594171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_594140 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBCluster_594142(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBCluster_594141(path: JsonNode; query: JsonNode;
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
  var valid_594143 = query.getOrDefault("DeletionProtection")
  valid_594143 = validateParameter(valid_594143, JBool, required = false, default = nil)
  if valid_594143 != nil:
    section.add "DeletionProtection", valid_594143
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594144 = query.getOrDefault("DBClusterIdentifier")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = nil)
  if valid_594144 != nil:
    section.add "DBClusterIdentifier", valid_594144
  var valid_594145 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "DBClusterParameterGroupName", valid_594145
  var valid_594146 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_594146 = validateParameter(valid_594146, JArray, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_594146
  var valid_594147 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_594147 = validateParameter(valid_594147, JArray, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_594147
  var valid_594148 = query.getOrDefault("BackupRetentionPeriod")
  valid_594148 = validateParameter(valid_594148, JInt, required = false, default = nil)
  if valid_594148 != nil:
    section.add "BackupRetentionPeriod", valid_594148
  var valid_594149 = query.getOrDefault("EngineVersion")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "EngineVersion", valid_594149
  var valid_594150 = query.getOrDefault("Action")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_594150 != nil:
    section.add "Action", valid_594150
  var valid_594151 = query.getOrDefault("ApplyImmediately")
  valid_594151 = validateParameter(valid_594151, JBool, required = false, default = nil)
  if valid_594151 != nil:
    section.add "ApplyImmediately", valid_594151
  var valid_594152 = query.getOrDefault("NewDBClusterIdentifier")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "NewDBClusterIdentifier", valid_594152
  var valid_594153 = query.getOrDefault("Port")
  valid_594153 = validateParameter(valid_594153, JInt, required = false, default = nil)
  if valid_594153 != nil:
    section.add "Port", valid_594153
  var valid_594154 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594154 = validateParameter(valid_594154, JArray, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "VpcSecurityGroupIds", valid_594154
  var valid_594155 = query.getOrDefault("MasterUserPassword")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "MasterUserPassword", valid_594155
  var valid_594156 = query.getOrDefault("Version")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594156 != nil:
    section.add "Version", valid_594156
  var valid_594157 = query.getOrDefault("PreferredBackupWindow")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "PreferredBackupWindow", valid_594157
  var valid_594158 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "PreferredMaintenanceWindow", valid_594158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594159 = header.getOrDefault("X-Amz-Signature")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Signature", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Content-Sha256", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Credential")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Credential", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Security-Token")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Security-Token", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-SignedHeaders", valid_594165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594166: Call_GetModifyDBCluster_594140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_594166.validator(path, query, header, formData, body)
  let scheme = call_594166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594166.url(scheme.get, call_594166.host, call_594166.base,
                         call_594166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594166, url, valid)

proc call*(call_594167: Call_GetModifyDBCluster_594140;
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
  var query_594168 = newJObject()
  add(query_594168, "DeletionProtection", newJBool(DeletionProtection))
  add(query_594168, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594168, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_594168.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_594168.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_594168, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594168, "EngineVersion", newJString(EngineVersion))
  add(query_594168, "Action", newJString(Action))
  add(query_594168, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_594168, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_594168, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_594168.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594168, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594168, "Version", newJString(Version))
  add(query_594168, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594168, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594167.call(nil, query_594168, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_594140(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_594141,
    base: "/", url: url_GetModifyDBCluster_594142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_594216 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBClusterParameterGroup_594218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_594217(path: JsonNode;
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
  var valid_594219 = query.getOrDefault("Action")
  valid_594219 = validateParameter(valid_594219, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_594219 != nil:
    section.add "Action", valid_594219
  var valid_594220 = query.getOrDefault("Version")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594220 != nil:
    section.add "Version", valid_594220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594221 = header.getOrDefault("X-Amz-Signature")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Signature", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Content-Sha256", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Date")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Date", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Credential")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Credential", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Security-Token")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Security-Token", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Algorithm")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Algorithm", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-SignedHeaders", valid_594227
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_594228 = formData.getOrDefault("Parameters")
  valid_594228 = validateParameter(valid_594228, JArray, required = true, default = nil)
  if valid_594228 != nil:
    section.add "Parameters", valid_594228
  var valid_594229 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594229 = validateParameter(valid_594229, JString, required = true,
                                 default = nil)
  if valid_594229 != nil:
    section.add "DBClusterParameterGroupName", valid_594229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_PostModifyDBClusterParameterGroup_594216;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_PostModifyDBClusterParameterGroup_594216;
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
  var query_594232 = newJObject()
  var formData_594233 = newJObject()
  add(query_594232, "Action", newJString(Action))
  if Parameters != nil:
    formData_594233.add "Parameters", Parameters
  add(formData_594233, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594232, "Version", newJString(Version))
  result = call_594231.call(nil, query_594232, nil, formData_594233, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_594216(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_594217, base: "/",
    url: url_PostModifyDBClusterParameterGroup_594218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_594199 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBClusterParameterGroup_594201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_594200(path: JsonNode;
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
  var valid_594202 = query.getOrDefault("Parameters")
  valid_594202 = validateParameter(valid_594202, JArray, required = true, default = nil)
  if valid_594202 != nil:
    section.add "Parameters", valid_594202
  var valid_594203 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594203 = validateParameter(valid_594203, JString, required = true,
                                 default = nil)
  if valid_594203 != nil:
    section.add "DBClusterParameterGroupName", valid_594203
  var valid_594204 = query.getOrDefault("Action")
  valid_594204 = validateParameter(valid_594204, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_594204 != nil:
    section.add "Action", valid_594204
  var valid_594205 = query.getOrDefault("Version")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594205 != nil:
    section.add "Version", valid_594205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594206 = header.getOrDefault("X-Amz-Signature")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Signature", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Date")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Date", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Credential")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Credential", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Algorithm")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Algorithm", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-SignedHeaders", valid_594212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594213: Call_GetModifyDBClusterParameterGroup_594199;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_594213.validator(path, query, header, formData, body)
  let scheme = call_594213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594213.url(scheme.get, call_594213.host, call_594213.base,
                         call_594213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594213, url, valid)

proc call*(call_594214: Call_GetModifyDBClusterParameterGroup_594199;
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
  var query_594215 = newJObject()
  if Parameters != nil:
    query_594215.add "Parameters", Parameters
  add(query_594215, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594215, "Action", newJString(Action))
  add(query_594215, "Version", newJString(Version))
  result = call_594214.call(nil, query_594215, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_594199(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_594200, base: "/",
    url: url_GetModifyDBClusterParameterGroup_594201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_594253 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBClusterSnapshotAttribute_594255(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_594254(path: JsonNode;
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
  var valid_594256 = query.getOrDefault("Action")
  valid_594256 = validateParameter(valid_594256, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_594256 != nil:
    section.add "Action", valid_594256
  var valid_594257 = query.getOrDefault("Version")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594257 != nil:
    section.add "Version", valid_594257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594258 = header.getOrDefault("X-Amz-Signature")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Signature", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Date")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Date", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Credential")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Credential", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Security-Token")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Security-Token", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Algorithm")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Algorithm", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-SignedHeaders", valid_594264
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
  var valid_594265 = formData.getOrDefault("AttributeName")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "AttributeName", valid_594265
  var valid_594266 = formData.getOrDefault("ValuesToAdd")
  valid_594266 = validateParameter(valid_594266, JArray, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "ValuesToAdd", valid_594266
  var valid_594267 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594267 = validateParameter(valid_594267, JString, required = true,
                                 default = nil)
  if valid_594267 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594267
  var valid_594268 = formData.getOrDefault("ValuesToRemove")
  valid_594268 = validateParameter(valid_594268, JArray, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "ValuesToRemove", valid_594268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594269: Call_PostModifyDBClusterSnapshotAttribute_594253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_594269.validator(path, query, header, formData, body)
  let scheme = call_594269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594269.url(scheme.get, call_594269.host, call_594269.base,
                         call_594269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594269, url, valid)

proc call*(call_594270: Call_PostModifyDBClusterSnapshotAttribute_594253;
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
  var query_594271 = newJObject()
  var formData_594272 = newJObject()
  add(formData_594272, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    formData_594272.add "ValuesToAdd", ValuesToAdd
  add(formData_594272, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594271, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_594272.add "ValuesToRemove", ValuesToRemove
  add(query_594271, "Version", newJString(Version))
  result = call_594270.call(nil, query_594271, nil, formData_594272, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_594253(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_594254, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_594255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_594234 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBClusterSnapshotAttribute_594236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_594235(path: JsonNode;
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
  var valid_594237 = query.getOrDefault("ValuesToRemove")
  valid_594237 = validateParameter(valid_594237, JArray, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "ValuesToRemove", valid_594237
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_594238 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594238
  var valid_594239 = query.getOrDefault("Action")
  valid_594239 = validateParameter(valid_594239, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_594239 != nil:
    section.add "Action", valid_594239
  var valid_594240 = query.getOrDefault("AttributeName")
  valid_594240 = validateParameter(valid_594240, JString, required = true,
                                 default = nil)
  if valid_594240 != nil:
    section.add "AttributeName", valid_594240
  var valid_594241 = query.getOrDefault("ValuesToAdd")
  valid_594241 = validateParameter(valid_594241, JArray, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "ValuesToAdd", valid_594241
  var valid_594242 = query.getOrDefault("Version")
  valid_594242 = validateParameter(valid_594242, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594242 != nil:
    section.add "Version", valid_594242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594243 = header.getOrDefault("X-Amz-Signature")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Signature", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Date")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Date", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Credential")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Credential", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Security-Token")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Security-Token", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Algorithm")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Algorithm", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-SignedHeaders", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_GetModifyDBClusterSnapshotAttribute_594234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_GetModifyDBClusterSnapshotAttribute_594234;
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
  var query_594252 = newJObject()
  if ValuesToRemove != nil:
    query_594252.add "ValuesToRemove", ValuesToRemove
  add(query_594252, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594252, "Action", newJString(Action))
  add(query_594252, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    query_594252.add "ValuesToAdd", ValuesToAdd
  add(query_594252, "Version", newJString(Version))
  result = call_594251.call(nil, query_594252, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_594234(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_594235, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_594236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_594296 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBInstance_594298(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_594297(path: JsonNode; query: JsonNode;
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
  var valid_594299 = query.getOrDefault("Action")
  valid_594299 = validateParameter(valid_594299, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594299 != nil:
    section.add "Action", valid_594299
  var valid_594300 = query.getOrDefault("Version")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594300 != nil:
    section.add "Version", valid_594300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Content-Sha256", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Credential")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Credential", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
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
  var valid_594308 = formData.getOrDefault("PromotionTier")
  valid_594308 = validateParameter(valid_594308, JInt, required = false, default = nil)
  if valid_594308 != nil:
    section.add "PromotionTier", valid_594308
  var valid_594309 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "PreferredMaintenanceWindow", valid_594309
  var valid_594310 = formData.getOrDefault("DBInstanceClass")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "DBInstanceClass", valid_594310
  var valid_594311 = formData.getOrDefault("CACertificateIdentifier")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "CACertificateIdentifier", valid_594311
  var valid_594312 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594312 = validateParameter(valid_594312, JBool, required = false, default = nil)
  if valid_594312 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594312
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594313 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594313 = validateParameter(valid_594313, JString, required = true,
                                 default = nil)
  if valid_594313 != nil:
    section.add "DBInstanceIdentifier", valid_594313
  var valid_594314 = formData.getOrDefault("ApplyImmediately")
  valid_594314 = validateParameter(valid_594314, JBool, required = false, default = nil)
  if valid_594314 != nil:
    section.add "ApplyImmediately", valid_594314
  var valid_594315 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "NewDBInstanceIdentifier", valid_594315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594316: Call_PostModifyDBInstance_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_594316.validator(path, query, header, formData, body)
  let scheme = call_594316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594316.url(scheme.get, call_594316.host, call_594316.base,
                         call_594316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594316, url, valid)

proc call*(call_594317: Call_PostModifyDBInstance_594296;
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
  var query_594318 = newJObject()
  var formData_594319 = newJObject()
  add(formData_594319, "PromotionTier", newJInt(PromotionTier))
  add(formData_594319, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594319, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594319, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_594319, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594319, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594319, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_594318, "Action", newJString(Action))
  add(formData_594319, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_594318, "Version", newJString(Version))
  result = call_594317.call(nil, query_594318, nil, formData_594319, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_594296(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_594297, base: "/",
    url: url_PostModifyDBInstance_594298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_594273 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBInstance_594275(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "NewDBInstanceIdentifier", valid_594276
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594277 = query.getOrDefault("DBInstanceIdentifier")
  valid_594277 = validateParameter(valid_594277, JString, required = true,
                                 default = nil)
  if valid_594277 != nil:
    section.add "DBInstanceIdentifier", valid_594277
  var valid_594278 = query.getOrDefault("PromotionTier")
  valid_594278 = validateParameter(valid_594278, JInt, required = false, default = nil)
  if valid_594278 != nil:
    section.add "PromotionTier", valid_594278
  var valid_594279 = query.getOrDefault("CACertificateIdentifier")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "CACertificateIdentifier", valid_594279
  var valid_594280 = query.getOrDefault("Action")
  valid_594280 = validateParameter(valid_594280, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594280 != nil:
    section.add "Action", valid_594280
  var valid_594281 = query.getOrDefault("ApplyImmediately")
  valid_594281 = validateParameter(valid_594281, JBool, required = false, default = nil)
  if valid_594281 != nil:
    section.add "ApplyImmediately", valid_594281
  var valid_594282 = query.getOrDefault("Version")
  valid_594282 = validateParameter(valid_594282, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594282 != nil:
    section.add "Version", valid_594282
  var valid_594283 = query.getOrDefault("DBInstanceClass")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "DBInstanceClass", valid_594283
  var valid_594284 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "PreferredMaintenanceWindow", valid_594284
  var valid_594285 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594285 = validateParameter(valid_594285, JBool, required = false, default = nil)
  if valid_594285 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594286 = header.getOrDefault("X-Amz-Signature")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Signature", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Content-Sha256", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Date")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Date", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Credential")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Credential", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Security-Token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Security-Token", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Algorithm")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Algorithm", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_GetModifyDBInstance_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_GetModifyDBInstance_594273;
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
  var query_594295 = newJObject()
  add(query_594295, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_594295, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594295, "PromotionTier", newJInt(PromotionTier))
  add(query_594295, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_594295, "Action", newJString(Action))
  add(query_594295, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_594295, "Version", newJString(Version))
  add(query_594295, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594295, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594295, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_594294.call(nil, query_594295, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_594273(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_594274, base: "/",
    url: url_GetModifyDBInstance_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_594338 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBSubnetGroup_594340(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_594339(path: JsonNode; query: JsonNode;
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
  var valid_594341 = query.getOrDefault("Action")
  valid_594341 = validateParameter(valid_594341, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594341 != nil:
    section.add "Action", valid_594341
  var valid_594342 = query.getOrDefault("Version")
  valid_594342 = validateParameter(valid_594342, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594342 != nil:
    section.add "Version", valid_594342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594343 = header.getOrDefault("X-Amz-Signature")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Signature", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Content-Sha256", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Date")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Date", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Credential")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Credential", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Algorithm")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Algorithm", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-SignedHeaders", valid_594349
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  section = newJObject()
  var valid_594350 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "DBSubnetGroupDescription", valid_594350
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594351 = formData.getOrDefault("DBSubnetGroupName")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = nil)
  if valid_594351 != nil:
    section.add "DBSubnetGroupName", valid_594351
  var valid_594352 = formData.getOrDefault("SubnetIds")
  valid_594352 = validateParameter(valid_594352, JArray, required = true, default = nil)
  if valid_594352 != nil:
    section.add "SubnetIds", valid_594352
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594353: Call_PostModifyDBSubnetGroup_594338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_594353.validator(path, query, header, formData, body)
  let scheme = call_594353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594353.url(scheme.get, call_594353.host, call_594353.base,
                         call_594353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594353, url, valid)

proc call*(call_594354: Call_PostModifyDBSubnetGroup_594338;
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
  var query_594355 = newJObject()
  var formData_594356 = newJObject()
  add(formData_594356, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594355, "Action", newJString(Action))
  add(formData_594356, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594355, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_594356.add "SubnetIds", SubnetIds
  result = call_594354.call(nil, query_594355, nil, formData_594356, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_594338(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_594339, base: "/",
    url: url_PostModifyDBSubnetGroup_594340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_594320 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBSubnetGroup_594322(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_594321(path: JsonNode; query: JsonNode;
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
  var valid_594323 = query.getOrDefault("SubnetIds")
  valid_594323 = validateParameter(valid_594323, JArray, required = true, default = nil)
  if valid_594323 != nil:
    section.add "SubnetIds", valid_594323
  var valid_594324 = query.getOrDefault("Action")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594324 != nil:
    section.add "Action", valid_594324
  var valid_594325 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "DBSubnetGroupDescription", valid_594325
  var valid_594326 = query.getOrDefault("DBSubnetGroupName")
  valid_594326 = validateParameter(valid_594326, JString, required = true,
                                 default = nil)
  if valid_594326 != nil:
    section.add "DBSubnetGroupName", valid_594326
  var valid_594327 = query.getOrDefault("Version")
  valid_594327 = validateParameter(valid_594327, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594327 != nil:
    section.add "Version", valid_594327
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594328 = header.getOrDefault("X-Amz-Signature")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Signature", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Content-Sha256", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Date")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Date", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Credential")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Credential", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Algorithm")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Algorithm", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-SignedHeaders", valid_594334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594335: Call_GetModifyDBSubnetGroup_594320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_594335.validator(path, query, header, formData, body)
  let scheme = call_594335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594335.url(scheme.get, call_594335.host, call_594335.base,
                         call_594335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594335, url, valid)

proc call*(call_594336: Call_GetModifyDBSubnetGroup_594320; SubnetIds: JsonNode;
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
  var query_594337 = newJObject()
  if SubnetIds != nil:
    query_594337.add "SubnetIds", SubnetIds
  add(query_594337, "Action", newJString(Action))
  add(query_594337, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594337, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594337, "Version", newJString(Version))
  result = call_594336.call(nil, query_594337, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_594320(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_594321, base: "/",
    url: url_GetModifyDBSubnetGroup_594322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_594374 = ref object of OpenApiRestCall_592348
proc url_PostRebootDBInstance_594376(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_594375(path: JsonNode; query: JsonNode;
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
  var valid_594377 = query.getOrDefault("Action")
  valid_594377 = validateParameter(valid_594377, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594377 != nil:
    section.add "Action", valid_594377
  var valid_594378 = query.getOrDefault("Version")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594378 != nil:
    section.add "Version", valid_594378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594379 = header.getOrDefault("X-Amz-Signature")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Signature", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Content-Sha256", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Date")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Date", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Credential")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Credential", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Security-Token")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Security-Token", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Algorithm")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Algorithm", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-SignedHeaders", valid_594385
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_594386 = formData.getOrDefault("ForceFailover")
  valid_594386 = validateParameter(valid_594386, JBool, required = false, default = nil)
  if valid_594386 != nil:
    section.add "ForceFailover", valid_594386
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594387 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594387 = validateParameter(valid_594387, JString, required = true,
                                 default = nil)
  if valid_594387 != nil:
    section.add "DBInstanceIdentifier", valid_594387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594388: Call_PostRebootDBInstance_594374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_594388.validator(path, query, header, formData, body)
  let scheme = call_594388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594388.url(scheme.get, call_594388.host, call_594388.base,
                         call_594388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594388, url, valid)

proc call*(call_594389: Call_PostRebootDBInstance_594374;
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
  var query_594390 = newJObject()
  var formData_594391 = newJObject()
  add(formData_594391, "ForceFailover", newJBool(ForceFailover))
  add(formData_594391, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594390, "Action", newJString(Action))
  add(query_594390, "Version", newJString(Version))
  result = call_594389.call(nil, query_594390, nil, formData_594391, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_594374(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_594375, base: "/",
    url: url_PostRebootDBInstance_594376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_594357 = ref object of OpenApiRestCall_592348
proc url_GetRebootDBInstance_594359(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_594358(path: JsonNode; query: JsonNode;
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
  var valid_594360 = query.getOrDefault("ForceFailover")
  valid_594360 = validateParameter(valid_594360, JBool, required = false, default = nil)
  if valid_594360 != nil:
    section.add "ForceFailover", valid_594360
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594361 = query.getOrDefault("DBInstanceIdentifier")
  valid_594361 = validateParameter(valid_594361, JString, required = true,
                                 default = nil)
  if valid_594361 != nil:
    section.add "DBInstanceIdentifier", valid_594361
  var valid_594362 = query.getOrDefault("Action")
  valid_594362 = validateParameter(valid_594362, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594362 != nil:
    section.add "Action", valid_594362
  var valid_594363 = query.getOrDefault("Version")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594363 != nil:
    section.add "Version", valid_594363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594364 = header.getOrDefault("X-Amz-Signature")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Signature", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Content-Sha256", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Date")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Date", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Credential")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Credential", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Security-Token")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Security-Token", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Algorithm")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Algorithm", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-SignedHeaders", valid_594370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_GetRebootDBInstance_594357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_GetRebootDBInstance_594357;
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
  var query_594373 = newJObject()
  add(query_594373, "ForceFailover", newJBool(ForceFailover))
  add(query_594373, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594373, "Action", newJString(Action))
  add(query_594373, "Version", newJString(Version))
  result = call_594372.call(nil, query_594373, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_594357(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_594358, base: "/",
    url: url_GetRebootDBInstance_594359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_594409 = ref object of OpenApiRestCall_592348
proc url_PostRemoveTagsFromResource_594411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_594410(path: JsonNode; query: JsonNode;
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
  var valid_594412 = query.getOrDefault("Action")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594412 != nil:
    section.add "Action", valid_594412
  var valid_594413 = query.getOrDefault("Version")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594413 != nil:
    section.add "Version", valid_594413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594414 = header.getOrDefault("X-Amz-Signature")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Signature", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Content-Sha256", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Date")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Date", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Security-Token")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Security-Token", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Algorithm")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Algorithm", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-SignedHeaders", valid_594420
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594421 = formData.getOrDefault("TagKeys")
  valid_594421 = validateParameter(valid_594421, JArray, required = true, default = nil)
  if valid_594421 != nil:
    section.add "TagKeys", valid_594421
  var valid_594422 = formData.getOrDefault("ResourceName")
  valid_594422 = validateParameter(valid_594422, JString, required = true,
                                 default = nil)
  if valid_594422 != nil:
    section.add "ResourceName", valid_594422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594423: Call_PostRemoveTagsFromResource_594409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_594423.validator(path, query, header, formData, body)
  let scheme = call_594423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594423.url(scheme.get, call_594423.host, call_594423.base,
                         call_594423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594423, url, valid)

proc call*(call_594424: Call_PostRemoveTagsFromResource_594409; TagKeys: JsonNode;
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
  var query_594425 = newJObject()
  var formData_594426 = newJObject()
  if TagKeys != nil:
    formData_594426.add "TagKeys", TagKeys
  add(query_594425, "Action", newJString(Action))
  add(query_594425, "Version", newJString(Version))
  add(formData_594426, "ResourceName", newJString(ResourceName))
  result = call_594424.call(nil, query_594425, nil, formData_594426, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_594409(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_594410, base: "/",
    url: url_PostRemoveTagsFromResource_594411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_594392 = ref object of OpenApiRestCall_592348
proc url_GetRemoveTagsFromResource_594394(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_594393(path: JsonNode; query: JsonNode;
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
  var valid_594395 = query.getOrDefault("ResourceName")
  valid_594395 = validateParameter(valid_594395, JString, required = true,
                                 default = nil)
  if valid_594395 != nil:
    section.add "ResourceName", valid_594395
  var valid_594396 = query.getOrDefault("TagKeys")
  valid_594396 = validateParameter(valid_594396, JArray, required = true, default = nil)
  if valid_594396 != nil:
    section.add "TagKeys", valid_594396
  var valid_594397 = query.getOrDefault("Action")
  valid_594397 = validateParameter(valid_594397, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594397 != nil:
    section.add "Action", valid_594397
  var valid_594398 = query.getOrDefault("Version")
  valid_594398 = validateParameter(valid_594398, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594398 != nil:
    section.add "Version", valid_594398
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594399 = header.getOrDefault("X-Amz-Signature")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Signature", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Content-Sha256", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Date")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Date", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Credential")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Credential", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Security-Token")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Security-Token", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Algorithm")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Algorithm", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-SignedHeaders", valid_594405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594406: Call_GetRemoveTagsFromResource_594392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_594406.validator(path, query, header, formData, body)
  let scheme = call_594406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594406.url(scheme.get, call_594406.host, call_594406.base,
                         call_594406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594406, url, valid)

proc call*(call_594407: Call_GetRemoveTagsFromResource_594392;
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
  var query_594408 = newJObject()
  add(query_594408, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_594408.add "TagKeys", TagKeys
  add(query_594408, "Action", newJString(Action))
  add(query_594408, "Version", newJString(Version))
  result = call_594407.call(nil, query_594408, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_594392(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_594393, base: "/",
    url: url_GetRemoveTagsFromResource_594394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_594445 = ref object of OpenApiRestCall_592348
proc url_PostResetDBClusterParameterGroup_594447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBClusterParameterGroup_594446(path: JsonNode;
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
  var valid_594448 = query.getOrDefault("Action")
  valid_594448 = validateParameter(valid_594448, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_594448 != nil:
    section.add "Action", valid_594448
  var valid_594449 = query.getOrDefault("Version")
  valid_594449 = validateParameter(valid_594449, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594449 != nil:
    section.add "Version", valid_594449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594450 = header.getOrDefault("X-Amz-Signature")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Signature", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Content-Sha256", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Date")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Date", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Credential")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Credential", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Security-Token")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Security-Token", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-SignedHeaders", valid_594456
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  section = newJObject()
  var valid_594457 = formData.getOrDefault("ResetAllParameters")
  valid_594457 = validateParameter(valid_594457, JBool, required = false, default = nil)
  if valid_594457 != nil:
    section.add "ResetAllParameters", valid_594457
  var valid_594458 = formData.getOrDefault("Parameters")
  valid_594458 = validateParameter(valid_594458, JArray, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "Parameters", valid_594458
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594459 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594459 = validateParameter(valid_594459, JString, required = true,
                                 default = nil)
  if valid_594459 != nil:
    section.add "DBClusterParameterGroupName", valid_594459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_PostResetDBClusterParameterGroup_594445;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_PostResetDBClusterParameterGroup_594445;
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
  var query_594462 = newJObject()
  var formData_594463 = newJObject()
  add(formData_594463, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_594462, "Action", newJString(Action))
  if Parameters != nil:
    formData_594463.add "Parameters", Parameters
  add(formData_594463, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594462, "Version", newJString(Version))
  result = call_594461.call(nil, query_594462, nil, formData_594463, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_594445(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_594446, base: "/",
    url: url_PostResetDBClusterParameterGroup_594447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_594427 = ref object of OpenApiRestCall_592348
proc url_GetResetDBClusterParameterGroup_594429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBClusterParameterGroup_594428(path: JsonNode;
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
  var valid_594430 = query.getOrDefault("Parameters")
  valid_594430 = validateParameter(valid_594430, JArray, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "Parameters", valid_594430
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594431 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594431 = validateParameter(valid_594431, JString, required = true,
                                 default = nil)
  if valid_594431 != nil:
    section.add "DBClusterParameterGroupName", valid_594431
  var valid_594432 = query.getOrDefault("ResetAllParameters")
  valid_594432 = validateParameter(valid_594432, JBool, required = false, default = nil)
  if valid_594432 != nil:
    section.add "ResetAllParameters", valid_594432
  var valid_594433 = query.getOrDefault("Action")
  valid_594433 = validateParameter(valid_594433, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_594433 != nil:
    section.add "Action", valid_594433
  var valid_594434 = query.getOrDefault("Version")
  valid_594434 = validateParameter(valid_594434, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594434 != nil:
    section.add "Version", valid_594434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594435 = header.getOrDefault("X-Amz-Signature")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Signature", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Content-Sha256", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Date")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Date", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Credential")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Credential", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Security-Token")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Security-Token", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-SignedHeaders", valid_594441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594442: Call_GetResetDBClusterParameterGroup_594427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_594442.validator(path, query, header, formData, body)
  let scheme = call_594442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594442.url(scheme.get, call_594442.host, call_594442.base,
                         call_594442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594442, url, valid)

proc call*(call_594443: Call_GetResetDBClusterParameterGroup_594427;
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
  var query_594444 = newJObject()
  if Parameters != nil:
    query_594444.add "Parameters", Parameters
  add(query_594444, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594444, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_594444, "Action", newJString(Action))
  add(query_594444, "Version", newJString(Version))
  result = call_594443.call(nil, query_594444, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_594427(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_594428, base: "/",
    url: url_GetResetDBClusterParameterGroup_594429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_594491 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBClusterFromSnapshot_594493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_594492(path: JsonNode;
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
  var valid_594494 = query.getOrDefault("Action")
  valid_594494 = validateParameter(valid_594494, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_594494 != nil:
    section.add "Action", valid_594494
  var valid_594495 = query.getOrDefault("Version")
  valid_594495 = validateParameter(valid_594495, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594495 != nil:
    section.add "Version", valid_594495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594496 = header.getOrDefault("X-Amz-Signature")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Signature", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Content-Sha256", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-Date")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Date", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Credential")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Credential", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Security-Token")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Security-Token", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Algorithm")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Algorithm", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
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
  var valid_594503 = formData.getOrDefault("Port")
  valid_594503 = validateParameter(valid_594503, JInt, required = false, default = nil)
  if valid_594503 != nil:
    section.add "Port", valid_594503
  var valid_594504 = formData.getOrDefault("EngineVersion")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "EngineVersion", valid_594504
  var valid_594505 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594505 = validateParameter(valid_594505, JArray, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "VpcSecurityGroupIds", valid_594505
  var valid_594506 = formData.getOrDefault("AvailabilityZones")
  valid_594506 = validateParameter(valid_594506, JArray, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "AvailabilityZones", valid_594506
  var valid_594507 = formData.getOrDefault("KmsKeyId")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "KmsKeyId", valid_594507
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594508 = formData.getOrDefault("Engine")
  valid_594508 = validateParameter(valid_594508, JString, required = true,
                                 default = nil)
  if valid_594508 != nil:
    section.add "Engine", valid_594508
  var valid_594509 = formData.getOrDefault("SnapshotIdentifier")
  valid_594509 = validateParameter(valid_594509, JString, required = true,
                                 default = nil)
  if valid_594509 != nil:
    section.add "SnapshotIdentifier", valid_594509
  var valid_594510 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_594510 = validateParameter(valid_594510, JArray, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594510
  var valid_594511 = formData.getOrDefault("Tags")
  valid_594511 = validateParameter(valid_594511, JArray, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "Tags", valid_594511
  var valid_594512 = formData.getOrDefault("DBSubnetGroupName")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "DBSubnetGroupName", valid_594512
  var valid_594513 = formData.getOrDefault("DBClusterIdentifier")
  valid_594513 = validateParameter(valid_594513, JString, required = true,
                                 default = nil)
  if valid_594513 != nil:
    section.add "DBClusterIdentifier", valid_594513
  var valid_594514 = formData.getOrDefault("DeletionProtection")
  valid_594514 = validateParameter(valid_594514, JBool, required = false, default = nil)
  if valid_594514 != nil:
    section.add "DeletionProtection", valid_594514
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594515: Call_PostRestoreDBClusterFromSnapshot_594491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_594515.validator(path, query, header, formData, body)
  let scheme = call_594515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594515.url(scheme.get, call_594515.host, call_594515.base,
                         call_594515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594515, url, valid)

proc call*(call_594516: Call_PostRestoreDBClusterFromSnapshot_594491;
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
  var query_594517 = newJObject()
  var formData_594518 = newJObject()
  add(formData_594518, "Port", newJInt(Port))
  add(formData_594518, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594518.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_594518.add "AvailabilityZones", AvailabilityZones
  add(formData_594518, "KmsKeyId", newJString(KmsKeyId))
  add(formData_594518, "Engine", newJString(Engine))
  add(formData_594518, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if EnableCloudwatchLogsExports != nil:
    formData_594518.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_594517, "Action", newJString(Action))
  if Tags != nil:
    formData_594518.add "Tags", Tags
  add(formData_594518, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594517, "Version", newJString(Version))
  add(formData_594518, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_594518, "DeletionProtection", newJBool(DeletionProtection))
  result = call_594516.call(nil, query_594517, nil, formData_594518, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_594491(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_594492, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_594493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_594464 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBClusterFromSnapshot_594466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_594465(path: JsonNode;
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
  var valid_594467 = query.getOrDefault("DeletionProtection")
  valid_594467 = validateParameter(valid_594467, JBool, required = false, default = nil)
  if valid_594467 != nil:
    section.add "DeletionProtection", valid_594467
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594468 = query.getOrDefault("Engine")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = nil)
  if valid_594468 != nil:
    section.add "Engine", valid_594468
  var valid_594469 = query.getOrDefault("SnapshotIdentifier")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = nil)
  if valid_594469 != nil:
    section.add "SnapshotIdentifier", valid_594469
  var valid_594470 = query.getOrDefault("Tags")
  valid_594470 = validateParameter(valid_594470, JArray, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "Tags", valid_594470
  var valid_594471 = query.getOrDefault("KmsKeyId")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "KmsKeyId", valid_594471
  var valid_594472 = query.getOrDefault("DBClusterIdentifier")
  valid_594472 = validateParameter(valid_594472, JString, required = true,
                                 default = nil)
  if valid_594472 != nil:
    section.add "DBClusterIdentifier", valid_594472
  var valid_594473 = query.getOrDefault("AvailabilityZones")
  valid_594473 = validateParameter(valid_594473, JArray, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "AvailabilityZones", valid_594473
  var valid_594474 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_594474 = validateParameter(valid_594474, JArray, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594474
  var valid_594475 = query.getOrDefault("EngineVersion")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "EngineVersion", valid_594475
  var valid_594476 = query.getOrDefault("Action")
  valid_594476 = validateParameter(valid_594476, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_594476 != nil:
    section.add "Action", valid_594476
  var valid_594477 = query.getOrDefault("Port")
  valid_594477 = validateParameter(valid_594477, JInt, required = false, default = nil)
  if valid_594477 != nil:
    section.add "Port", valid_594477
  var valid_594478 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594478 = validateParameter(valid_594478, JArray, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "VpcSecurityGroupIds", valid_594478
  var valid_594479 = query.getOrDefault("DBSubnetGroupName")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "DBSubnetGroupName", valid_594479
  var valid_594480 = query.getOrDefault("Version")
  valid_594480 = validateParameter(valid_594480, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594480 != nil:
    section.add "Version", valid_594480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594481 = header.getOrDefault("X-Amz-Signature")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Signature", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Content-Sha256", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Date")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Date", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Credential")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Credential", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Security-Token")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Security-Token", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Algorithm")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Algorithm", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-SignedHeaders", valid_594487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594488: Call_GetRestoreDBClusterFromSnapshot_594464;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_594488.validator(path, query, header, formData, body)
  let scheme = call_594488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594488.url(scheme.get, call_594488.host, call_594488.base,
                         call_594488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594488, url, valid)

proc call*(call_594489: Call_GetRestoreDBClusterFromSnapshot_594464;
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
  var query_594490 = newJObject()
  add(query_594490, "DeletionProtection", newJBool(DeletionProtection))
  add(query_594490, "Engine", newJString(Engine))
  add(query_594490, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if Tags != nil:
    query_594490.add "Tags", Tags
  add(query_594490, "KmsKeyId", newJString(KmsKeyId))
  add(query_594490, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if AvailabilityZones != nil:
    query_594490.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    query_594490.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_594490, "EngineVersion", newJString(EngineVersion))
  add(query_594490, "Action", newJString(Action))
  add(query_594490, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_594490.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594490, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594490, "Version", newJString(Version))
  result = call_594489.call(nil, query_594490, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_594464(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_594465, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_594466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_594545 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBClusterToPointInTime_594547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_594546(path: JsonNode;
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
  var valid_594548 = query.getOrDefault("Action")
  valid_594548 = validateParameter(valid_594548, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_594548 != nil:
    section.add "Action", valid_594548
  var valid_594549 = query.getOrDefault("Version")
  valid_594549 = validateParameter(valid_594549, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594549 != nil:
    section.add "Version", valid_594549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594550 = header.getOrDefault("X-Amz-Signature")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Signature", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Content-Sha256", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Date")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Date", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Credential")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Credential", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Security-Token")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Security-Token", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Algorithm")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Algorithm", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-SignedHeaders", valid_594556
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
  var valid_594557 = formData.getOrDefault("Port")
  valid_594557 = validateParameter(valid_594557, JInt, required = false, default = nil)
  if valid_594557 != nil:
    section.add "Port", valid_594557
  var valid_594558 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594558 = validateParameter(valid_594558, JArray, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "VpcSecurityGroupIds", valid_594558
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_594559 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_594559 = validateParameter(valid_594559, JString, required = true,
                                 default = nil)
  if valid_594559 != nil:
    section.add "SourceDBClusterIdentifier", valid_594559
  var valid_594560 = formData.getOrDefault("KmsKeyId")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "KmsKeyId", valid_594560
  var valid_594561 = formData.getOrDefault("UseLatestRestorableTime")
  valid_594561 = validateParameter(valid_594561, JBool, required = false, default = nil)
  if valid_594561 != nil:
    section.add "UseLatestRestorableTime", valid_594561
  var valid_594562 = formData.getOrDefault("RestoreToTime")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "RestoreToTime", valid_594562
  var valid_594563 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_594563 = validateParameter(valid_594563, JArray, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594563
  var valid_594564 = formData.getOrDefault("Tags")
  valid_594564 = validateParameter(valid_594564, JArray, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "Tags", valid_594564
  var valid_594565 = formData.getOrDefault("DBSubnetGroupName")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "DBSubnetGroupName", valid_594565
  var valid_594566 = formData.getOrDefault("DBClusterIdentifier")
  valid_594566 = validateParameter(valid_594566, JString, required = true,
                                 default = nil)
  if valid_594566 != nil:
    section.add "DBClusterIdentifier", valid_594566
  var valid_594567 = formData.getOrDefault("DeletionProtection")
  valid_594567 = validateParameter(valid_594567, JBool, required = false, default = nil)
  if valid_594567 != nil:
    section.add "DeletionProtection", valid_594567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594568: Call_PostRestoreDBClusterToPointInTime_594545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_594568.validator(path, query, header, formData, body)
  let scheme = call_594568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594568.url(scheme.get, call_594568.host, call_594568.base,
                         call_594568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594568, url, valid)

proc call*(call_594569: Call_PostRestoreDBClusterToPointInTime_594545;
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
  var query_594570 = newJObject()
  var formData_594571 = newJObject()
  add(formData_594571, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_594571.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594571, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_594571, "KmsKeyId", newJString(KmsKeyId))
  add(formData_594571, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_594571, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    formData_594571.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_594570, "Action", newJString(Action))
  if Tags != nil:
    formData_594571.add "Tags", Tags
  add(formData_594571, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594570, "Version", newJString(Version))
  add(formData_594571, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_594571, "DeletionProtection", newJBool(DeletionProtection))
  result = call_594569.call(nil, query_594570, nil, formData_594571, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_594545(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_594546, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_594547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_594519 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBClusterToPointInTime_594521(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_594520(path: JsonNode;
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
  var valid_594522 = query.getOrDefault("DeletionProtection")
  valid_594522 = validateParameter(valid_594522, JBool, required = false, default = nil)
  if valid_594522 != nil:
    section.add "DeletionProtection", valid_594522
  var valid_594523 = query.getOrDefault("UseLatestRestorableTime")
  valid_594523 = validateParameter(valid_594523, JBool, required = false, default = nil)
  if valid_594523 != nil:
    section.add "UseLatestRestorableTime", valid_594523
  var valid_594524 = query.getOrDefault("Tags")
  valid_594524 = validateParameter(valid_594524, JArray, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "Tags", valid_594524
  var valid_594525 = query.getOrDefault("KmsKeyId")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "KmsKeyId", valid_594525
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594526 = query.getOrDefault("DBClusterIdentifier")
  valid_594526 = validateParameter(valid_594526, JString, required = true,
                                 default = nil)
  if valid_594526 != nil:
    section.add "DBClusterIdentifier", valid_594526
  var valid_594527 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_594527 = validateParameter(valid_594527, JString, required = true,
                                 default = nil)
  if valid_594527 != nil:
    section.add "SourceDBClusterIdentifier", valid_594527
  var valid_594528 = query.getOrDefault("RestoreToTime")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "RestoreToTime", valid_594528
  var valid_594529 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_594529 = validateParameter(valid_594529, JArray, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594529
  var valid_594530 = query.getOrDefault("Action")
  valid_594530 = validateParameter(valid_594530, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_594530 != nil:
    section.add "Action", valid_594530
  var valid_594531 = query.getOrDefault("Port")
  valid_594531 = validateParameter(valid_594531, JInt, required = false, default = nil)
  if valid_594531 != nil:
    section.add "Port", valid_594531
  var valid_594532 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594532 = validateParameter(valid_594532, JArray, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "VpcSecurityGroupIds", valid_594532
  var valid_594533 = query.getOrDefault("DBSubnetGroupName")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "DBSubnetGroupName", valid_594533
  var valid_594534 = query.getOrDefault("Version")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594534 != nil:
    section.add "Version", valid_594534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594535 = header.getOrDefault("X-Amz-Signature")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Signature", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Content-Sha256", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Date")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Date", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Credential")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Credential", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Security-Token")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Security-Token", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Algorithm")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Algorithm", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-SignedHeaders", valid_594541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594542: Call_GetRestoreDBClusterToPointInTime_594519;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_594542.validator(path, query, header, formData, body)
  let scheme = call_594542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594542.url(scheme.get, call_594542.host, call_594542.base,
                         call_594542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594542, url, valid)

proc call*(call_594543: Call_GetRestoreDBClusterToPointInTime_594519;
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
  var query_594544 = newJObject()
  add(query_594544, "DeletionProtection", newJBool(DeletionProtection))
  add(query_594544, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_594544.add "Tags", Tags
  add(query_594544, "KmsKeyId", newJString(KmsKeyId))
  add(query_594544, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594544, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_594544, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    query_594544.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_594544, "Action", newJString(Action))
  add(query_594544, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_594544.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594544, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594544, "Version", newJString(Version))
  result = call_594543.call(nil, query_594544, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_594519(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_594520, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_594521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_594588 = ref object of OpenApiRestCall_592348
proc url_PostStartDBCluster_594590(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStartDBCluster_594589(path: JsonNode; query: JsonNode;
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
  var valid_594591 = query.getOrDefault("Action")
  valid_594591 = validateParameter(valid_594591, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_594591 != nil:
    section.add "Action", valid_594591
  var valid_594592 = query.getOrDefault("Version")
  valid_594592 = validateParameter(valid_594592, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594592 != nil:
    section.add "Version", valid_594592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594593 = header.getOrDefault("X-Amz-Signature")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Signature", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Content-Sha256", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Date")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Date", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Credential")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Credential", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Security-Token")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Security-Token", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Algorithm")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Algorithm", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-SignedHeaders", valid_594599
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594600 = formData.getOrDefault("DBClusterIdentifier")
  valid_594600 = validateParameter(valid_594600, JString, required = true,
                                 default = nil)
  if valid_594600 != nil:
    section.add "DBClusterIdentifier", valid_594600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594601: Call_PostStartDBCluster_594588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_594601.validator(path, query, header, formData, body)
  let scheme = call_594601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594601.url(scheme.get, call_594601.host, call_594601.base,
                         call_594601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594601, url, valid)

proc call*(call_594602: Call_PostStartDBCluster_594588;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_594603 = newJObject()
  var formData_594604 = newJObject()
  add(query_594603, "Action", newJString(Action))
  add(query_594603, "Version", newJString(Version))
  add(formData_594604, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_594602.call(nil, query_594603, nil, formData_594604, nil)

var postStartDBCluster* = Call_PostStartDBCluster_594588(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_594589, base: "/",
    url: url_PostStartDBCluster_594590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_594572 = ref object of OpenApiRestCall_592348
proc url_GetStartDBCluster_594574(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStartDBCluster_594573(path: JsonNode; query: JsonNode;
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
  var valid_594575 = query.getOrDefault("DBClusterIdentifier")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = nil)
  if valid_594575 != nil:
    section.add "DBClusterIdentifier", valid_594575
  var valid_594576 = query.getOrDefault("Action")
  valid_594576 = validateParameter(valid_594576, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_594576 != nil:
    section.add "Action", valid_594576
  var valid_594577 = query.getOrDefault("Version")
  valid_594577 = validateParameter(valid_594577, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594577 != nil:
    section.add "Version", valid_594577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594578 = header.getOrDefault("X-Amz-Signature")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Signature", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Content-Sha256", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Date")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Date", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Credential")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Credential", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Security-Token")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Security-Token", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Algorithm")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Algorithm", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-SignedHeaders", valid_594584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594585: Call_GetStartDBCluster_594572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_594585.validator(path, query, header, formData, body)
  let scheme = call_594585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594585.url(scheme.get, call_594585.host, call_594585.base,
                         call_594585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594585, url, valid)

proc call*(call_594586: Call_GetStartDBCluster_594572; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594587 = newJObject()
  add(query_594587, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594587, "Action", newJString(Action))
  add(query_594587, "Version", newJString(Version))
  result = call_594586.call(nil, query_594587, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_594572(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_594573,
    base: "/", url: url_GetStartDBCluster_594574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_594621 = ref object of OpenApiRestCall_592348
proc url_PostStopDBCluster_594623(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStopDBCluster_594622(path: JsonNode; query: JsonNode;
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
  var valid_594624 = query.getOrDefault("Action")
  valid_594624 = validateParameter(valid_594624, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_594624 != nil:
    section.add "Action", valid_594624
  var valid_594625 = query.getOrDefault("Version")
  valid_594625 = validateParameter(valid_594625, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594625 != nil:
    section.add "Version", valid_594625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594626 = header.getOrDefault("X-Amz-Signature")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Signature", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Content-Sha256", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Date")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Date", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Credential")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Credential", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Security-Token")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Security-Token", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Algorithm")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Algorithm", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-SignedHeaders", valid_594632
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594633 = formData.getOrDefault("DBClusterIdentifier")
  valid_594633 = validateParameter(valid_594633, JString, required = true,
                                 default = nil)
  if valid_594633 != nil:
    section.add "DBClusterIdentifier", valid_594633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594634: Call_PostStopDBCluster_594621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_594634.validator(path, query, header, formData, body)
  let scheme = call_594634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594634.url(scheme.get, call_594634.host, call_594634.base,
                         call_594634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594634, url, valid)

proc call*(call_594635: Call_PostStopDBCluster_594621; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_594636 = newJObject()
  var formData_594637 = newJObject()
  add(query_594636, "Action", newJString(Action))
  add(query_594636, "Version", newJString(Version))
  add(formData_594637, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_594635.call(nil, query_594636, nil, formData_594637, nil)

var postStopDBCluster* = Call_PostStopDBCluster_594621(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_594622,
    base: "/", url: url_PostStopDBCluster_594623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_594605 = ref object of OpenApiRestCall_592348
proc url_GetStopDBCluster_594607(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStopDBCluster_594606(path: JsonNode; query: JsonNode;
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
  var valid_594608 = query.getOrDefault("DBClusterIdentifier")
  valid_594608 = validateParameter(valid_594608, JString, required = true,
                                 default = nil)
  if valid_594608 != nil:
    section.add "DBClusterIdentifier", valid_594608
  var valid_594609 = query.getOrDefault("Action")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_594609 != nil:
    section.add "Action", valid_594609
  var valid_594610 = query.getOrDefault("Version")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594610 != nil:
    section.add "Version", valid_594610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594611 = header.getOrDefault("X-Amz-Signature")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Signature", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Content-Sha256", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Date")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Date", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Credential")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Credential", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Security-Token")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Security-Token", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-Algorithm")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Algorithm", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-SignedHeaders", valid_594617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594618: Call_GetStopDBCluster_594605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_594618.validator(path, query, header, formData, body)
  let scheme = call_594618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594618.url(scheme.get, call_594618.host, call_594618.base,
                         call_594618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594618, url, valid)

proc call*(call_594619: Call_GetStopDBCluster_594605; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594620 = newJObject()
  add(query_594620, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594620, "Action", newJString(Action))
  add(query_594620, "Version", newJString(Version))
  result = call_594619.call(nil, query_594620, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_594605(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_594606,
    base: "/", url: url_GetStopDBCluster_594607,
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

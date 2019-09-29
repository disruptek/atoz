
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Groups
## version: 2017-11-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Resource Groups</fullname> <p>AWS Resource Groups lets you organize AWS resources such as Amazon EC2 instances, Amazon Relational Database Service databases, and Amazon S3 buckets into groups using criteria that you define as tags. A resource group is a collection of resources that match the resource types specified in a query, and share one or more tags or portions of tags. You can create a group of resources based on their roles in your cloud infrastructure, lifecycle stages, regions, application layers, or virtually any criteria. Resource groups enable you to automate management tasks, such as those in AWS Systems Manager Automation documents, on tag-related resources in AWS Systems Manager. Groups of tagged resources also let you quickly view a custom console in AWS Systems Manager that shows AWS Config compliance and other monitoring data about member resources.</p> <p>To create a resource group, build a resource query, and specify tags that identify the criteria that members of the group have in common. Tags are key-value pairs.</p> <p>For more information about Resource Groups, see the <a href="https://docs.aws.amazon.com/ARG/latest/userguide/welcome.html">AWS Resource Groups User Guide</a>.</p> <p>AWS Resource Groups uses a REST-compliant API that you can use to perform the following types of operations.</p> <ul> <li> <p>Create, Read, Update, and Delete (CRUD) operations on resource groups and resource query entities</p> </li> <li> <p>Applying, editing, and removing tags from resource groups</p> </li> <li> <p>Resolving resource group member ARNs so they can be returned as search results</p> </li> <li> <p>Getting data about resources that are members of a group</p> </li> <li> <p>Searching AWS resources based on a resource query</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/resource-groups/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "resource-groups.ap-northeast-1.amazonaws.com", "ap-southeast-1": "resource-groups.ap-southeast-1.amazonaws.com", "us-west-2": "resource-groups.us-west-2.amazonaws.com", "eu-west-2": "resource-groups.eu-west-2.amazonaws.com", "ap-northeast-3": "resource-groups.ap-northeast-3.amazonaws.com", "eu-central-1": "resource-groups.eu-central-1.amazonaws.com", "us-east-2": "resource-groups.us-east-2.amazonaws.com", "us-east-1": "resource-groups.us-east-1.amazonaws.com", "cn-northwest-1": "resource-groups.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "resource-groups.ap-south-1.amazonaws.com", "eu-north-1": "resource-groups.eu-north-1.amazonaws.com", "ap-northeast-2": "resource-groups.ap-northeast-2.amazonaws.com", "us-west-1": "resource-groups.us-west-1.amazonaws.com", "us-gov-east-1": "resource-groups.us-gov-east-1.amazonaws.com", "eu-west-3": "resource-groups.eu-west-3.amazonaws.com", "cn-north-1": "resource-groups.cn-north-1.amazonaws.com.cn", "sa-east-1": "resource-groups.sa-east-1.amazonaws.com", "eu-west-1": "resource-groups.eu-west-1.amazonaws.com", "us-gov-west-1": "resource-groups.us-gov-west-1.amazonaws.com", "ap-southeast-2": "resource-groups.ap-southeast-2.amazonaws.com", "ca-central-1": "resource-groups.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "resource-groups.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "resource-groups.ap-southeast-1.amazonaws.com",
      "us-west-2": "resource-groups.us-west-2.amazonaws.com",
      "eu-west-2": "resource-groups.eu-west-2.amazonaws.com",
      "ap-northeast-3": "resource-groups.ap-northeast-3.amazonaws.com",
      "eu-central-1": "resource-groups.eu-central-1.amazonaws.com",
      "us-east-2": "resource-groups.us-east-2.amazonaws.com",
      "us-east-1": "resource-groups.us-east-1.amazonaws.com",
      "cn-northwest-1": "resource-groups.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "resource-groups.ap-south-1.amazonaws.com",
      "eu-north-1": "resource-groups.eu-north-1.amazonaws.com",
      "ap-northeast-2": "resource-groups.ap-northeast-2.amazonaws.com",
      "us-west-1": "resource-groups.us-west-1.amazonaws.com",
      "us-gov-east-1": "resource-groups.us-gov-east-1.amazonaws.com",
      "eu-west-3": "resource-groups.eu-west-3.amazonaws.com",
      "cn-north-1": "resource-groups.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "resource-groups.sa-east-1.amazonaws.com",
      "eu-west-1": "resource-groups.eu-west-1.amazonaws.com",
      "us-gov-west-1": "resource-groups.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "resource-groups.ap-southeast-2.amazonaws.com",
      "ca-central-1": "resource-groups.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "resource-groups"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateGroup_593774 = ref object of OpenApiRestCall_593437
proc url_CreateGroup_593776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGroup_593775(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Content-Sha256", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Algorithm")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Algorithm", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Signature")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Signature", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-SignedHeaders", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Credential")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Credential", valid_593894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_CreateGroup_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593989: Call_CreateGroup_593774; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   body: JObject (required)
  var body_593990 = newJObject()
  if body != nil:
    body_593990 = body
  result = call_593989.call(nil, nil, nil, nil, body_593990)

var createGroup* = Call_CreateGroup_593774(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups",
                                        validator: validate_CreateGroup_593775,
                                        base: "/", url: url_CreateGroup_593776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_594058 = ref object of OpenApiRestCall_593437
proc url_UpdateGroup_594060(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateGroup_594059(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group for which you want to update its description.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594061 = path.getOrDefault("GroupName")
  valid_594061 = validateParameter(valid_594061, JString, required = true,
                                 default = nil)
  if valid_594061 != nil:
    section.add "GroupName", valid_594061
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Security-Token")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Security-Token", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_UpdateGroup_594058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_UpdateGroup_594058; GroupName: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to update its description.
  ##   body: JObject (required)
  var path_594072 = newJObject()
  var body_594073 = newJObject()
  add(path_594072, "GroupName", newJString(GroupName))
  if body != nil:
    body_594073 = body
  result = call_594071.call(path_594072, nil, nil, nil, body_594073)

var updateGroup* = Call_UpdateGroup_594058(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_UpdateGroup_594059,
                                        base: "/", url: url_UpdateGroup_594060,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_594029 = ref object of OpenApiRestCall_593437
proc url_GetGroup_594031(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetGroup_594030(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594046 = path.getOrDefault("GroupName")
  valid_594046 = validateParameter(valid_594046, JString, required = true,
                                 default = nil)
  if valid_594046 != nil:
    section.add "GroupName", valid_594046
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Security-Token")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Security-Token", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594054: Call_GetGroup_594029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified resource group.
  ## 
  let valid = call_594054.validator(path, query, header, formData, body)
  let scheme = call_594054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594054.url(scheme.get, call_594054.host, call_594054.base,
                         call_594054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594054, url, valid)

proc call*(call_594055: Call_GetGroup_594029; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_594056 = newJObject()
  add(path_594056, "GroupName", newJString(GroupName))
  result = call_594055.call(path_594056, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_594029(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/groups/{GroupName}",
                                  validator: validate_GetGroup_594030, base: "/",
                                  url: url_GetGroup_594031,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_594074 = ref object of OpenApiRestCall_593437
proc url_DeleteGroup_594076(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteGroup_594075(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594077 = path.getOrDefault("GroupName")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "GroupName", valid_594077
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Signature")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Signature", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_DeleteGroup_594074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_DeleteGroup_594074; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   GroupName: string (required)
  ##            : The name of the resource group to delete.
  var path_594087 = newJObject()
  add(path_594087, "GroupName", newJString(GroupName))
  result = call_594086.call(path_594087, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_594074(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_DeleteGroup_594075,
                                        base: "/", url: url_DeleteGroup_594076,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_594102 = ref object of OpenApiRestCall_593437
proc url_UpdateGroupQuery_594104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateGroupQuery_594103(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the resource query of a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group for which you want to edit the query.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594105 = path.getOrDefault("GroupName")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = nil)
  if valid_594105 != nil:
    section.add "GroupName", valid_594105
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Content-Sha256", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Algorithm", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594114: Call_UpdateGroupQuery_594102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource query of a group.
  ## 
  let valid = call_594114.validator(path, query, header, formData, body)
  let scheme = call_594114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594114.url(scheme.get, call_594114.host, call_594114.base,
                         call_594114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594114, url, valid)

proc call*(call_594115: Call_UpdateGroupQuery_594102; GroupName: string;
          body: JsonNode): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to edit the query.
  ##   body: JObject (required)
  var path_594116 = newJObject()
  var body_594117 = newJObject()
  add(path_594116, "GroupName", newJString(GroupName))
  if body != nil:
    body_594117 = body
  result = call_594115.call(path_594116, nil, nil, nil, body_594117)

var updateGroupQuery* = Call_UpdateGroupQuery_594102(name: "updateGroupQuery",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_UpdateGroupQuery_594103,
    base: "/", url: url_UpdateGroupQuery_594104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_594088 = ref object of OpenApiRestCall_593437
proc url_GetGroupQuery_594090(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetGroupQuery_594089(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the resource query associated with the specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594091 = path.getOrDefault("GroupName")
  valid_594091 = validateParameter(valid_594091, JString, required = true,
                                 default = nil)
  if valid_594091 != nil:
    section.add "GroupName", valid_594091
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Security-Token")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Security-Token", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_GetGroupQuery_594088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the resource query associated with the specified resource group.
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_GetGroupQuery_594088; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_594101 = newJObject()
  add(path_594101, "GroupName", newJString(GroupName))
  result = call_594100.call(path_594101, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_594088(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_594089,
    base: "/", url: url_GetGroupQuery_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_594132 = ref object of OpenApiRestCall_593437
proc url_Tag_594134(protocol: Scheme; host: string; base: string; route: string;
                   path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_Tag_594133(path: JsonNode; query: JsonNode; header: JsonNode;
                        formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource to which to add tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_594135 = path.getOrDefault("Arn")
  valid_594135 = validateParameter(valid_594135, JString, required = true,
                                 default = nil)
  if valid_594135 != nil:
    section.add "Arn", valid_594135
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Content-Sha256", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Algorithm")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Algorithm", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Signature")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Signature", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594144: Call_Tag_594132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_594144.validator(path, query, header, formData, body)
  let scheme = call_594144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594144.url(scheme.get, call_594144.host, call_594144.base,
                         call_594144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594144, url, valid)

proc call*(call_594145: Call_Tag_594132; Arn: string; body: JsonNode): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   Arn: string (required)
  ##      : The ARN of the resource to which to add tags.
  ##   body: JObject (required)
  var path_594146 = newJObject()
  var body_594147 = newJObject()
  add(path_594146, "Arn", newJString(Arn))
  if body != nil:
    body_594147 = body
  result = call_594145.call(path_594146, nil, nil, nil, body_594147)

var tag* = Call_Tag_594132(name: "tag", meth: HttpMethod.HttpPut,
                        host: "resource-groups.amazonaws.com",
                        route: "/resources/{Arn}/tags", validator: validate_Tag_594133,
                        base: "/", url: url_Tag_594134,
                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_594118 = ref object of OpenApiRestCall_593437
proc url_GetTags_594120(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetTags_594119(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_594121 = path.getOrDefault("Arn")
  valid_594121 = validateParameter(valid_594121, JString, required = true,
                                 default = nil)
  if valid_594121 != nil:
    section.add "Arn", valid_594121
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594122 = header.getOrDefault("X-Amz-Date")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Date", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Security-Token")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Security-Token", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594129: Call_GetTags_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  let valid = call_594129.validator(path, query, header, formData, body)
  let scheme = call_594129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594129.url(scheme.get, call_594129.host, call_594129.base,
                         call_594129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594129, url, valid)

proc call*(call_594130: Call_GetTags_594118; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   Arn: string (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  var path_594131 = newJObject()
  add(path_594131, "Arn", newJString(Arn))
  result = call_594130.call(path_594131, nil, nil, nil, nil)

var getTags* = Call_GetTags_594118(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "resource-groups.amazonaws.com",
                                route: "/resources/{Arn}/tags",
                                validator: validate_GetTags_594119, base: "/",
                                url: url_GetTags_594120,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_594148 = ref object of OpenApiRestCall_593437
proc url_Untag_594150(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_Untag_594149(path: JsonNode; query: JsonNode; header: JsonNode;
                          formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Arn: JString (required)
  ##      : The ARN of the resource from which to remove tags.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Arn` field"
  var valid_594151 = path.getOrDefault("Arn")
  valid_594151 = validateParameter(valid_594151, JString, required = true,
                                 default = nil)
  if valid_594151 != nil:
    section.add "Arn", valid_594151
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594152 = header.getOrDefault("X-Amz-Date")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Date", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Security-Token")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Security-Token", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_Untag_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a specified resource.
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_Untag_594148; Arn: string; body: JsonNode): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   Arn: string (required)
  ##      : The ARN of the resource from which to remove tags.
  ##   body: JObject (required)
  var path_594162 = newJObject()
  var body_594163 = newJObject()
  add(path_594162, "Arn", newJString(Arn))
  if body != nil:
    body_594163 = body
  result = call_594161.call(path_594162, nil, nil, nil, body_594163)

var untag* = Call_Untag_594148(name: "untag", meth: HttpMethod.HttpPatch,
                            host: "resource-groups.amazonaws.com",
                            route: "/resources/{Arn}/tags",
                            validator: validate_Untag_594149, base: "/",
                            url: url_Untag_594150,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_594164 = ref object of OpenApiRestCall_593437
proc url_ListGroupResources_594166(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/resource-identifiers-list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListGroupResources_594165(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the resource group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_594167 = path.getOrDefault("GroupName")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "GroupName", valid_594167
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594168 = query.getOrDefault("NextToken")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "NextToken", valid_594168
  var valid_594169 = query.getOrDefault("maxResults")
  valid_594169 = validateParameter(valid_594169, JInt, required = false, default = nil)
  if valid_594169 != nil:
    section.add "maxResults", valid_594169
  var valid_594170 = query.getOrDefault("nextToken")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "nextToken", valid_594170
  var valid_594171 = query.getOrDefault("MaxResults")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "MaxResults", valid_594171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594172 = header.getOrDefault("X-Amz-Date")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Date", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Security-Token")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Security-Token", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Content-Sha256", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Algorithm")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Algorithm", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Signature")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Signature", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-SignedHeaders", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Credential")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Credential", valid_594178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594180: Call_ListGroupResources_594164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  let valid = call_594180.validator(path, query, header, formData, body)
  let scheme = call_594180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594180.url(scheme.get, call_594180.host, call_594180.base,
                         call_594180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594180, url, valid)

proc call*(call_594181: Call_ListGroupResources_594164; GroupName: string;
          body: JsonNode; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupResources
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of group member ARNs that are returned in a single call by ListGroupResources, in paginated output. By default, this number is 50.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated ListGroupResources request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594182 = newJObject()
  var query_594183 = newJObject()
  var body_594184 = newJObject()
  add(path_594182, "GroupName", newJString(GroupName))
  add(query_594183, "NextToken", newJString(NextToken))
  add(query_594183, "maxResults", newJInt(maxResults))
  add(query_594183, "nextToken", newJString(nextToken))
  if body != nil:
    body_594184 = body
  add(query_594183, "MaxResults", newJString(MaxResults))
  result = call_594181.call(path_594182, query_594183, nil, nil, body_594184)

var listGroupResources* = Call_ListGroupResources_594164(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_594165, base: "/",
    url: url_ListGroupResources_594166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_594185 = ref object of OpenApiRestCall_593437
proc url_ListGroups_594187(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGroups_594186(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing resource groups in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   nextToken: JString
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594188 = query.getOrDefault("NextToken")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "NextToken", valid_594188
  var valid_594189 = query.getOrDefault("maxResults")
  valid_594189 = validateParameter(valid_594189, JInt, required = false, default = nil)
  if valid_594189 != nil:
    section.add "maxResults", valid_594189
  var valid_594190 = query.getOrDefault("nextToken")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "nextToken", valid_594190
  var valid_594191 = query.getOrDefault("MaxResults")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "MaxResults", valid_594191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594192 = header.getOrDefault("X-Amz-Date")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Date", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Security-Token")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Security-Token", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Content-Sha256", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Algorithm")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Algorithm", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Signature")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Signature", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-SignedHeaders", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594200: Call_ListGroups_594185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing resource groups in your account.
  ## 
  let valid = call_594200.validator(path, query, header, formData, body)
  let scheme = call_594200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594200.url(scheme.get, call_594200.host, call_594200.base,
                         call_594200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594200, url, valid)

proc call*(call_594201: Call_ListGroups_594185; body: JsonNode;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Returns a list of existing resource groups in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of resource group results that are returned by ListGroups in paginated output. By default, this number is 50.
  ##   nextToken: string
  ##            : The NextToken value that is returned in a paginated <code>ListGroups</code> request. To get the next page of results, run the call again, add the NextToken parameter, and specify the NextToken value.
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594202 = newJObject()
  var body_594203 = newJObject()
  add(query_594202, "NextToken", newJString(NextToken))
  add(query_594202, "maxResults", newJInt(maxResults))
  add(query_594202, "nextToken", newJString(nextToken))
  if body != nil:
    body_594203 = body
  add(query_594202, "MaxResults", newJString(MaxResults))
  result = call_594201.call(nil, query_594202, nil, nil, body_594203)

var listGroups* = Call_ListGroups_594185(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/groups-list",
                                      validator: validate_ListGroups_594186,
                                      base: "/", url: url_ListGroups_594187,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_594204 = ref object of OpenApiRestCall_593437
proc url_SearchResources_594206(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchResources_594205(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594207 = query.getOrDefault("NextToken")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "NextToken", valid_594207
  var valid_594208 = query.getOrDefault("MaxResults")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "MaxResults", valid_594208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Signature", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-SignedHeaders", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Credential")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Credential", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594217: Call_SearchResources_594204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  let valid = call_594217.validator(path, query, header, formData, body)
  let scheme = call_594217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594217.url(scheme.get, call_594217.host, call_594217.base,
                         call_594217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594217, url, valid)

proc call*(call_594218: Call_SearchResources_594204; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594219 = newJObject()
  var body_594220 = newJObject()
  add(query_594219, "NextToken", newJString(NextToken))
  if body != nil:
    body_594220 = body
  add(query_594219, "MaxResults", newJString(MaxResults))
  result = call_594218.call(nil, query_594219, nil, nil, body_594220)

var searchResources* = Call_SearchResources_594204(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_594205,
    base: "/", url: url_SearchResources_594206, schemes: {Scheme.Https, Scheme.Http})
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

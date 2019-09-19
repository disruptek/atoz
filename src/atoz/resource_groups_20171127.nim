
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateGroup_772933 = ref object of OpenApiRestCall_772597
proc url_CreateGroup_772935(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_CreateGroup_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group with a specified name, description, and resource query.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_CreateGroup_772933; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group with a specified name, description, and resource query.
  ##   body: JObject (required)
  var body_773149 = newJObject()
  if body != nil:
    body_773149 = body
  result = call_773148.call(nil, nil, nil, nil, body_773149)

var createGroup* = Call_CreateGroup_772933(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups",
                                        validator: validate_CreateGroup_772934,
                                        base: "/", url: url_CreateGroup_772935,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_773217 = ref object of OpenApiRestCall_772597
proc url_UpdateGroup_773219(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGroup_773218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773220 = path.getOrDefault("GroupName")
  valid_773220 = validateParameter(valid_773220, JString, required = true,
                                 default = nil)
  if valid_773220 != nil:
    section.add "GroupName", valid_773220
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
  var valid_773221 = header.getOrDefault("X-Amz-Date")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Date", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Security-Token")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Security-Token", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_UpdateGroup_773217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_UpdateGroup_773217; GroupName: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates an existing group with a new or changed description. You cannot update the name of a resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to update its description.
  ##   body: JObject (required)
  var path_773231 = newJObject()
  var body_773232 = newJObject()
  add(path_773231, "GroupName", newJString(GroupName))
  if body != nil:
    body_773232 = body
  result = call_773230.call(path_773231, nil, nil, nil, body_773232)

var updateGroup* = Call_UpdateGroup_773217(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_UpdateGroup_773218,
                                        base: "/", url: url_UpdateGroup_773219,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_773188 = ref object of OpenApiRestCall_772597
proc url_GetGroup_773190(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroup_773189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773205 = path.getOrDefault("GroupName")
  valid_773205 = validateParameter(valid_773205, JString, required = true,
                                 default = nil)
  if valid_773205 != nil:
    section.add "GroupName", valid_773205
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
  var valid_773206 = header.getOrDefault("X-Amz-Date")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Date", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Security-Token")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Security-Token", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_GetGroup_773188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified resource group.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_GetGroup_773188; GroupName: string): Recallable =
  ## getGroup
  ## Returns information about a specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_773215 = newJObject()
  add(path_773215, "GroupName", newJString(GroupName))
  result = call_773214.call(path_773215, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_773188(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "resource-groups.amazonaws.com",
                                  route: "/groups/{GroupName}",
                                  validator: validate_GetGroup_773189, base: "/",
                                  url: url_GetGroup_773190,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_773233 = ref object of OpenApiRestCall_772597
proc url_DeleteGroup_773235(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteGroup_773234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773236 = path.getOrDefault("GroupName")
  valid_773236 = validateParameter(valid_773236, JString, required = true,
                                 default = nil)
  if valid_773236 != nil:
    section.add "GroupName", valid_773236
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
  var valid_773237 = header.getOrDefault("X-Amz-Date")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Date", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Security-Token")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Security-Token", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Content-Sha256", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Algorithm")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Algorithm", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Signature")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Signature", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-SignedHeaders", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Credential")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Credential", valid_773243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_DeleteGroup_773233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_DeleteGroup_773233; GroupName: string): Recallable =
  ## deleteGroup
  ## Deletes a specified resource group. Deleting a resource group does not delete resources that are members of the group; it only deletes the group structure.
  ##   GroupName: string (required)
  ##            : The name of the resource group to delete.
  var path_773246 = newJObject()
  add(path_773246, "GroupName", newJString(GroupName))
  result = call_773245.call(path_773246, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_773233(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "resource-groups.amazonaws.com",
                                        route: "/groups/{GroupName}",
                                        validator: validate_DeleteGroup_773234,
                                        base: "/", url: url_DeleteGroup_773235,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupQuery_773261 = ref object of OpenApiRestCall_772597
proc url_UpdateGroupQuery_773263(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGroupQuery_773262(path: JsonNode; query: JsonNode;
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
  var valid_773264 = path.getOrDefault("GroupName")
  valid_773264 = validateParameter(valid_773264, JString, required = true,
                                 default = nil)
  if valid_773264 != nil:
    section.add "GroupName", valid_773264
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Content-Sha256", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Algorithm", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Signature", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-SignedHeaders", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Credential")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Credential", valid_773271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773273: Call_UpdateGroupQuery_773261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource query of a group.
  ## 
  let valid = call_773273.validator(path, query, header, formData, body)
  let scheme = call_773273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773273.url(scheme.get, call_773273.host, call_773273.base,
                         call_773273.route, valid.getOrDefault("path"))
  result = hook(call_773273, url, valid)

proc call*(call_773274: Call_UpdateGroupQuery_773261; GroupName: string;
          body: JsonNode): Recallable =
  ## updateGroupQuery
  ## Updates the resource query of a group.
  ##   GroupName: string (required)
  ##            : The name of the resource group for which you want to edit the query.
  ##   body: JObject (required)
  var path_773275 = newJObject()
  var body_773276 = newJObject()
  add(path_773275, "GroupName", newJString(GroupName))
  if body != nil:
    body_773276 = body
  result = call_773274.call(path_773275, nil, nil, nil, body_773276)

var updateGroupQuery* = Call_UpdateGroupQuery_773261(name: "updateGroupQuery",
    meth: HttpMethod.HttpPut, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_UpdateGroupQuery_773262,
    base: "/", url: url_UpdateGroupQuery_773263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupQuery_773247 = ref object of OpenApiRestCall_772597
proc url_GetGroupQuery_773249(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/query")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroupQuery_773248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773250 = path.getOrDefault("GroupName")
  valid_773250 = validateParameter(valid_773250, JString, required = true,
                                 default = nil)
  if valid_773250 != nil:
    section.add "GroupName", valid_773250
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
  var valid_773251 = header.getOrDefault("X-Amz-Date")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Date", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Security-Token")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Security-Token", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_GetGroupQuery_773247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the resource query associated with the specified resource group.
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_GetGroupQuery_773247; GroupName: string): Recallable =
  ## getGroupQuery
  ## Returns the resource query associated with the specified resource group.
  ##   GroupName: string (required)
  ##            : The name of the resource group.
  var path_773260 = newJObject()
  add(path_773260, "GroupName", newJString(GroupName))
  result = call_773259.call(path_773260, nil, nil, nil, nil)

var getGroupQuery* = Call_GetGroupQuery_773247(name: "getGroupQuery",
    meth: HttpMethod.HttpGet, host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/query", validator: validate_GetGroupQuery_773248,
    base: "/", url: url_GetGroupQuery_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Tag_773291 = ref object of OpenApiRestCall_772597
proc url_Tag_773293(protocol: Scheme; host: string; base: string; route: string;
                   path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_Tag_773292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773294 = path.getOrDefault("Arn")
  valid_773294 = validateParameter(valid_773294, JString, required = true,
                                 default = nil)
  if valid_773294 != nil:
    section.add "Arn", valid_773294
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Content-Sha256", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Algorithm")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Algorithm", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Signature")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Signature", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-SignedHeaders", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Credential")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Credential", valid_773301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773303: Call_Tag_773291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_773303.validator(path, query, header, formData, body)
  let scheme = call_773303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773303.url(scheme.get, call_773303.host, call_773303.base,
                         call_773303.route, valid.getOrDefault("path"))
  result = hook(call_773303, url, valid)

proc call*(call_773304: Call_Tag_773291; Arn: string; body: JsonNode): Recallable =
  ## tag
  ## Adds tags to a resource group with the specified ARN. Existing tags on a resource group are not changed if they are not specified in the request parameters.
  ##   Arn: string (required)
  ##      : The ARN of the resource to which to add tags.
  ##   body: JObject (required)
  var path_773305 = newJObject()
  var body_773306 = newJObject()
  add(path_773305, "Arn", newJString(Arn))
  if body != nil:
    body_773306 = body
  result = call_773304.call(path_773305, nil, nil, nil, body_773306)

var tag* = Call_Tag_773291(name: "tag", meth: HttpMethod.HttpPut,
                        host: "resource-groups.amazonaws.com",
                        route: "/resources/{Arn}/tags", validator: validate_Tag_773292,
                        base: "/", url: url_Tag_773293,
                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_773277 = ref object of OpenApiRestCall_772597
proc url_GetTags_773279(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetTags_773278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773280 = path.getOrDefault("Arn")
  valid_773280 = validateParameter(valid_773280, JString, required = true,
                                 default = nil)
  if valid_773280 != nil:
    section.add "Arn", valid_773280
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
  var valid_773281 = header.getOrDefault("X-Amz-Date")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Date", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Security-Token")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Security-Token", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773288: Call_GetTags_773277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ## 
  let valid = call_773288.validator(path, query, header, formData, body)
  let scheme = call_773288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773288.url(scheme.get, call_773288.host, call_773288.base,
                         call_773288.route, valid.getOrDefault("path"))
  result = hook(call_773288, url, valid)

proc call*(call_773289: Call_GetTags_773277; Arn: string): Recallable =
  ## getTags
  ## Returns a list of tags that are associated with a resource group, specified by an ARN.
  ##   Arn: string (required)
  ##      : The ARN of the resource group for which you want a list of tags. The resource must exist within the account you are using.
  var path_773290 = newJObject()
  add(path_773290, "Arn", newJString(Arn))
  result = call_773289.call(path_773290, nil, nil, nil, nil)

var getTags* = Call_GetTags_773277(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "resource-groups.amazonaws.com",
                                route: "/resources/{Arn}/tags",
                                validator: validate_GetTags_773278, base: "/",
                                url: url_GetTags_773279,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_Untag_773307 = ref object of OpenApiRestCall_772597
proc url_Untag_773309(protocol: Scheme; host: string; base: string; route: string;
                     path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Arn" in path, "`Arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "Arn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_Untag_773308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773310 = path.getOrDefault("Arn")
  valid_773310 = validateParameter(valid_773310, JString, required = true,
                                 default = nil)
  if valid_773310 != nil:
    section.add "Arn", valid_773310
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
  var valid_773311 = header.getOrDefault("X-Amz-Date")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Date", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Security-Token")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Security-Token", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_Untag_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a specified resource.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_Untag_773307; Arn: string; body: JsonNode): Recallable =
  ## untag
  ## Deletes specified tags from a specified resource.
  ##   Arn: string (required)
  ##      : The ARN of the resource from which to remove tags.
  ##   body: JObject (required)
  var path_773321 = newJObject()
  var body_773322 = newJObject()
  add(path_773321, "Arn", newJString(Arn))
  if body != nil:
    body_773322 = body
  result = call_773320.call(path_773321, nil, nil, nil, body_773322)

var untag* = Call_Untag_773307(name: "untag", meth: HttpMethod.HttpPatch,
                            host: "resource-groups.amazonaws.com",
                            route: "/resources/{Arn}/tags",
                            validator: validate_Untag_773308, base: "/",
                            url: url_Untag_773309,
                            schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupResources_773323 = ref object of OpenApiRestCall_772597
proc url_ListGroupResources_773325(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/resource-identifiers-list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListGroupResources_773324(path: JsonNode; query: JsonNode;
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
  var valid_773326 = path.getOrDefault("GroupName")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "GroupName", valid_773326
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
  var valid_773327 = query.getOrDefault("NextToken")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "NextToken", valid_773327
  var valid_773328 = query.getOrDefault("maxResults")
  valid_773328 = validateParameter(valid_773328, JInt, required = false, default = nil)
  if valid_773328 != nil:
    section.add "maxResults", valid_773328
  var valid_773329 = query.getOrDefault("nextToken")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "nextToken", valid_773329
  var valid_773330 = query.getOrDefault("MaxResults")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "MaxResults", valid_773330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773331 = header.getOrDefault("X-Amz-Date")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Date", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Security-Token")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Security-Token", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Content-Sha256", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Algorithm")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Algorithm", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Signature")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Signature", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-SignedHeaders", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Credential")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Credential", valid_773337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773339: Call_ListGroupResources_773323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ARNs of resources that are members of a specified resource group.
  ## 
  let valid = call_773339.validator(path, query, header, formData, body)
  let scheme = call_773339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773339.url(scheme.get, call_773339.host, call_773339.base,
                         call_773339.route, valid.getOrDefault("path"))
  result = hook(call_773339, url, valid)

proc call*(call_773340: Call_ListGroupResources_773323; GroupName: string;
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
  var path_773341 = newJObject()
  var query_773342 = newJObject()
  var body_773343 = newJObject()
  add(path_773341, "GroupName", newJString(GroupName))
  add(query_773342, "NextToken", newJString(NextToken))
  add(query_773342, "maxResults", newJInt(maxResults))
  add(query_773342, "nextToken", newJString(nextToken))
  if body != nil:
    body_773343 = body
  add(query_773342, "MaxResults", newJString(MaxResults))
  result = call_773340.call(path_773341, query_773342, nil, nil, body_773343)

var listGroupResources* = Call_ListGroupResources_773323(
    name: "listGroupResources", meth: HttpMethod.HttpPost,
    host: "resource-groups.amazonaws.com",
    route: "/groups/{GroupName}/resource-identifiers-list",
    validator: validate_ListGroupResources_773324, base: "/",
    url: url_ListGroupResources_773325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_773344 = ref object of OpenApiRestCall_772597
proc url_ListGroups_773346(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGroups_773345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773347 = query.getOrDefault("NextToken")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "NextToken", valid_773347
  var valid_773348 = query.getOrDefault("maxResults")
  valid_773348 = validateParameter(valid_773348, JInt, required = false, default = nil)
  if valid_773348 != nil:
    section.add "maxResults", valid_773348
  var valid_773349 = query.getOrDefault("nextToken")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "nextToken", valid_773349
  var valid_773350 = query.getOrDefault("MaxResults")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "MaxResults", valid_773350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773351 = header.getOrDefault("X-Amz-Date")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Date", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Security-Token")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Security-Token", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Content-Sha256", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Algorithm")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Algorithm", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Signature")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Signature", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-SignedHeaders", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Credential")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Credential", valid_773357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773359: Call_ListGroups_773344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing resource groups in your account.
  ## 
  let valid = call_773359.validator(path, query, header, formData, body)
  let scheme = call_773359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773359.url(scheme.get, call_773359.host, call_773359.base,
                         call_773359.route, valid.getOrDefault("path"))
  result = hook(call_773359, url, valid)

proc call*(call_773360: Call_ListGroups_773344; body: JsonNode;
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
  var query_773361 = newJObject()
  var body_773362 = newJObject()
  add(query_773361, "NextToken", newJString(NextToken))
  add(query_773361, "maxResults", newJInt(maxResults))
  add(query_773361, "nextToken", newJString(nextToken))
  if body != nil:
    body_773362 = body
  add(query_773361, "MaxResults", newJString(MaxResults))
  result = call_773360.call(nil, query_773361, nil, nil, body_773362)

var listGroups* = Call_ListGroups_773344(name: "listGroups",
                                      meth: HttpMethod.HttpPost,
                                      host: "resource-groups.amazonaws.com",
                                      route: "/groups-list",
                                      validator: validate_ListGroups_773345,
                                      base: "/", url: url_ListGroups_773346,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchResources_773363 = ref object of OpenApiRestCall_772597
proc url_SearchResources_773365(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchResources_773364(path: JsonNode; query: JsonNode;
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
  var valid_773366 = query.getOrDefault("NextToken")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "NextToken", valid_773366
  var valid_773367 = query.getOrDefault("MaxResults")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "MaxResults", valid_773367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Content-Sha256", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773376: Call_SearchResources_773363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ## 
  let valid = call_773376.validator(path, query, header, formData, body)
  let scheme = call_773376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773376.url(scheme.get, call_773376.host, call_773376.base,
                         call_773376.route, valid.getOrDefault("path"))
  result = hook(call_773376, url, valid)

proc call*(call_773377: Call_SearchResources_773363; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchResources
  ## Returns a list of AWS resource identifiers that matches a specified query. The query uses the same format as a resource query in a CreateGroup or UpdateGroupQuery operation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773378 = newJObject()
  var body_773379 = newJObject()
  add(query_773378, "NextToken", newJString(NextToken))
  if body != nil:
    body_773379 = body
  add(query_773378, "MaxResults", newJString(MaxResults))
  result = call_773377.call(nil, query_773378, nil, nil, body_773379)

var searchResources* = Call_SearchResources_773363(name: "searchResources",
    meth: HttpMethod.HttpPost, host: "resource-groups.amazonaws.com",
    route: "/resources/search", validator: validate_SearchResources_773364,
    base: "/", url: url_SearchResources_773365, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

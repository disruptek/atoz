
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Data Lifecycle Manager
## version: 2018-01-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Data Lifecycle Manager</fullname> <p>With Amazon Data Lifecycle Manager, you can manage the lifecycle of your AWS resources. You create lifecycle policies, which are used to automate operations on the specified resources.</p> <p>Amazon DLM supports Amazon EBS volumes and snapshots. For information about using Amazon DLM with Amazon EBS, see <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snapshot-lifecycle.html">Automating the Amazon EBS Snapshot Lifecycle</a> in the <i>Amazon EC2 User Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dlm/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dlm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dlm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dlm.us-west-2.amazonaws.com",
                           "eu-west-2": "dlm.eu-west-2.amazonaws.com", "ap-northeast-3": "dlm.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "dlm.eu-central-1.amazonaws.com",
                           "us-east-2": "dlm.us-east-2.amazonaws.com",
                           "us-east-1": "dlm.us-east-1.amazonaws.com", "cn-northwest-1": "dlm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "dlm.ap-south-1.amazonaws.com",
                           "eu-north-1": "dlm.eu-north-1.amazonaws.com", "ap-northeast-2": "dlm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dlm.us-west-1.amazonaws.com",
                           "us-gov-east-1": "dlm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dlm.eu-west-3.amazonaws.com",
                           "cn-north-1": "dlm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dlm.sa-east-1.amazonaws.com",
                           "eu-west-1": "dlm.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "dlm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dlm.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "dlm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dlm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dlm.ap-southeast-1.amazonaws.com",
      "us-west-2": "dlm.us-west-2.amazonaws.com",
      "eu-west-2": "dlm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dlm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dlm.eu-central-1.amazonaws.com",
      "us-east-2": "dlm.us-east-2.amazonaws.com",
      "us-east-1": "dlm.us-east-1.amazonaws.com",
      "cn-northwest-1": "dlm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dlm.ap-south-1.amazonaws.com",
      "eu-north-1": "dlm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dlm.ap-northeast-2.amazonaws.com",
      "us-west-1": "dlm.us-west-1.amazonaws.com",
      "us-gov-east-1": "dlm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dlm.eu-west-3.amazonaws.com",
      "cn-north-1": "dlm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dlm.sa-east-1.amazonaws.com",
      "eu-west-1": "dlm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dlm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dlm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dlm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dlm"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLifecyclePolicy_606200 = ref object of OpenApiRestCall_605589
proc url_CreateLifecyclePolicy_606202(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLifecyclePolicy_606201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_CreateLifecyclePolicy_606200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_CreateLifecyclePolicy_606200; body: JsonNode): Recallable =
  ## createLifecyclePolicy
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ##   body: JObject (required)
  var body_606213 = newJObject()
  if body != nil:
    body_606213 = body
  result = call_606212.call(nil, nil, nil, nil, body_606213)

var createLifecyclePolicy* = Call_CreateLifecyclePolicy_606200(
    name: "createLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_CreateLifecyclePolicy_606201, base: "/",
    url: url_CreateLifecyclePolicy_606202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicies_605927 = ref object of OpenApiRestCall_605589
proc url_GetLifecyclePolicies_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetLifecyclePolicies_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: JString
  ##        : The activation state.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  section = newJObject()
  var valid_606041 = query.getOrDefault("tagsToAdd")
  valid_606041 = validateParameter(valid_606041, JArray, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "tagsToAdd", valid_606041
  var valid_606055 = query.getOrDefault("state")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = newJString("ENABLED"))
  if valid_606055 != nil:
    section.add "state", valid_606055
  var valid_606056 = query.getOrDefault("resourceTypes")
  valid_606056 = validateParameter(valid_606056, JArray, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "resourceTypes", valid_606056
  var valid_606057 = query.getOrDefault("policyIds")
  valid_606057 = validateParameter(valid_606057, JArray, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "policyIds", valid_606057
  var valid_606058 = query.getOrDefault("targetTags")
  valid_606058 = validateParameter(valid_606058, JArray, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "targetTags", valid_606058
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606059 = header.getOrDefault("X-Amz-Signature")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Signature", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Content-Sha256", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Date")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Date", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Credential")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Credential", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Security-Token")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Security-Token", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Algorithm")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Algorithm", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-SignedHeaders", valid_606065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606088: Call_GetLifecyclePolicies_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  let valid = call_606088.validator(path, query, header, formData, body)
  let scheme = call_606088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606088.url(scheme.get, call_606088.host, call_606088.base,
                         call_606088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606088, url, valid)

proc call*(call_606159: Call_GetLifecyclePolicies_605927;
          tagsToAdd: JsonNode = nil; state: string = "ENABLED";
          resourceTypes: JsonNode = nil; policyIds: JsonNode = nil;
          targetTags: JsonNode = nil): Recallable =
  ## getLifecyclePolicies
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: string
  ##        : The activation state.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  var query_606160 = newJObject()
  if tagsToAdd != nil:
    query_606160.add "tagsToAdd", tagsToAdd
  add(query_606160, "state", newJString(state))
  if resourceTypes != nil:
    query_606160.add "resourceTypes", resourceTypes
  if policyIds != nil:
    query_606160.add "policyIds", policyIds
  if targetTags != nil:
    query_606160.add "targetTags", targetTags
  result = call_606159.call(nil, query_606160, nil, nil, nil)

var getLifecyclePolicies* = Call_GetLifecyclePolicies_605927(
    name: "getLifecyclePolicies", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_GetLifecyclePolicies_605928, base: "/",
    url: url_GetLifecyclePolicies_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_606214 = ref object of OpenApiRestCall_605589
proc url_GetLifecyclePolicy_606216(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLifecyclePolicy_606215(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_606231 = path.getOrDefault("policyId")
  valid_606231 = validateParameter(valid_606231, JString, required = true,
                                 default = nil)
  if valid_606231 != nil:
    section.add "policyId", valid_606231
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606232 = header.getOrDefault("X-Amz-Signature")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Signature", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Content-Sha256", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Date")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Date", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Credential")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Credential", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Security-Token")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Security-Token", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Algorithm")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Algorithm", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-SignedHeaders", valid_606238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_GetLifecyclePolicy_606214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_GetLifecyclePolicy_606214; policyId: string): Recallable =
  ## getLifecyclePolicy
  ## Gets detailed information about the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_606241 = newJObject()
  add(path_606241, "policyId", newJString(policyId))
  result = call_606240.call(path_606241, nil, nil, nil, nil)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_606214(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpGet, host: "dlm.amazonaws.com",
    route: "/policies/{policyId}/", validator: validate_GetLifecyclePolicy_606215,
    base: "/", url: url_GetLifecyclePolicy_606216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_606242 = ref object of OpenApiRestCall_605589
proc url_DeleteLifecyclePolicy_606244(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLifecyclePolicy_606243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_606245 = path.getOrDefault("policyId")
  valid_606245 = validateParameter(valid_606245, JString, required = true,
                                 default = nil)
  if valid_606245 != nil:
    section.add "policyId", valid_606245
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeleteLifecyclePolicy_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteLifecyclePolicy_606242; policyId: string): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_606255 = newJObject()
  add(path_606255, "policyId", newJString(policyId))
  result = call_606254.call(path_606255, nil, nil, nil, nil)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_606242(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpDelete,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_DeleteLifecyclePolicy_606243, base: "/",
    url: url_DeleteLifecyclePolicy_606244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606270 = ref object of OpenApiRestCall_605589
proc url_TagResource_606272(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606271(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606273 = path.getOrDefault("resourceArn")
  valid_606273 = validateParameter(valid_606273, JString, required = true,
                                 default = nil)
  if valid_606273 != nil:
    section.add "resourceArn", valid_606273
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606274 = header.getOrDefault("X-Amz-Signature")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Signature", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Content-Sha256", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Date")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Date", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Credential")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Credential", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606282: Call_TagResource_606270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource.
  ## 
  let valid = call_606282.validator(path, query, header, formData, body)
  let scheme = call_606282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606282.url(scheme.get, call_606282.host, call_606282.base,
                         call_606282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606282, url, valid)

proc call*(call_606283: Call_TagResource_606270; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_606284 = newJObject()
  var body_606285 = newJObject()
  add(path_606284, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606285 = body
  result = call_606283.call(path_606284, nil, nil, nil, body_606285)

var tagResource* = Call_TagResource_606270(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dlm.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606271,
                                        base: "/", url: url_TagResource_606272,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606256 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606258(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606259 = path.getOrDefault("resourceArn")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = nil)
  if valid_606259 != nil:
    section.add "resourceArn", valid_606259
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606267: Call_ListTagsForResource_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_606267.validator(path, query, header, formData, body)
  let scheme = call_606267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606267.url(scheme.get, call_606267.host, call_606267.base,
                         call_606267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606267, url, valid)

proc call*(call_606268: Call_ListTagsForResource_606256; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_606269 = newJObject()
  add(path_606269, "resourceArn", newJString(resourceArn))
  result = call_606268.call(path_606269, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606256(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606257, base: "/",
    url: url_ListTagsForResource_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606286 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606288(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606287(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606289 = path.getOrDefault("resourceArn")
  valid_606289 = validateParameter(valid_606289, JString, required = true,
                                 default = nil)
  if valid_606289 != nil:
    section.add "resourceArn", valid_606289
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606290 = query.getOrDefault("tagKeys")
  valid_606290 = validateParameter(valid_606290, JArray, required = true, default = nil)
  if valid_606290 != nil:
    section.add "tagKeys", valid_606290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606291 = header.getOrDefault("X-Amz-Signature")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Signature", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Content-Sha256", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Date")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Date", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Credential")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Credential", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Security-Token")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Security-Token", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Algorithm")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Algorithm", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-SignedHeaders", valid_606297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_UntagResource_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_UntagResource_606286; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  var path_606300 = newJObject()
  var query_606301 = newJObject()
  add(path_606300, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606301.add "tagKeys", tagKeys
  result = call_606299.call(path_606300, query_606301, nil, nil, nil)

var untagResource* = Call_UntagResource_606286(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dlm.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606287,
    base: "/", url: url_UntagResource_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLifecyclePolicy_606302 = ref object of OpenApiRestCall_605589
proc url_UpdateLifecyclePolicy_606304(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "policyId" in path, "`policyId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/policies/"),
               (kind: VariableSegment, value: "policyId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLifecyclePolicy_606303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified lifecycle policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   policyId: JString (required)
  ##           : The identifier of the lifecycle policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `policyId` field"
  var valid_606305 = path.getOrDefault("policyId")
  valid_606305 = validateParameter(valid_606305, JString, required = true,
                                 default = nil)
  if valid_606305 != nil:
    section.add "policyId", valid_606305
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606306 = header.getOrDefault("X-Amz-Signature")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Signature", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Content-Sha256", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Date")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Date", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Credential")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Credential", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Security-Token")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Security-Token", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Algorithm")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Algorithm", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-SignedHeaders", valid_606312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_UpdateLifecyclePolicy_606302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified lifecycle policy.
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_UpdateLifecyclePolicy_606302; policyId: string;
          body: JsonNode): Recallable =
  ## updateLifecyclePolicy
  ## Updates the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  ##   body: JObject (required)
  var path_606316 = newJObject()
  var body_606317 = newJObject()
  add(path_606316, "policyId", newJString(policyId))
  if body != nil:
    body_606317 = body
  result = call_606315.call(path_606316, nil, nil, nil, body_606317)

var updateLifecyclePolicy* = Call_UpdateLifecyclePolicy_606302(
    name: "updateLifecyclePolicy", meth: HttpMethod.HttpPatch,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}",
    validator: validate_UpdateLifecyclePolicy_606303, base: "/",
    url: url_UpdateLifecyclePolicy_606304, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)

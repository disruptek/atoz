
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLifecyclePolicy_601047 = ref object of OpenApiRestCall_600437
proc url_CreateLifecyclePolicy_601049(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLifecyclePolicy_601048(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_CreateLifecyclePolicy_601047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_CreateLifecyclePolicy_601047; body: JsonNode): Recallable =
  ## createLifecyclePolicy
  ## Creates a policy to manage the lifecycle of the specified AWS resources. You can create up to 100 lifecycle policies.
  ##   body: JObject (required)
  var body_601060 = newJObject()
  if body != nil:
    body_601060 = body
  result = call_601059.call(nil, nil, nil, nil, body_601060)

var createLifecyclePolicy* = Call_CreateLifecyclePolicy_601047(
    name: "createLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_CreateLifecyclePolicy_601048, base: "/",
    url: url_CreateLifecyclePolicy_601049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicies_600774 = ref object of OpenApiRestCall_600437
proc url_GetLifecyclePolicies_600776(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicies_600775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: JString
  ##        : The activation state.
  section = newJObject()
  var valid_600888 = query.getOrDefault("targetTags")
  valid_600888 = validateParameter(valid_600888, JArray, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "targetTags", valid_600888
  var valid_600889 = query.getOrDefault("policyIds")
  valid_600889 = validateParameter(valid_600889, JArray, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "policyIds", valid_600889
  var valid_600890 = query.getOrDefault("resourceTypes")
  valid_600890 = validateParameter(valid_600890, JArray, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "resourceTypes", valid_600890
  var valid_600891 = query.getOrDefault("tagsToAdd")
  valid_600891 = validateParameter(valid_600891, JArray, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "tagsToAdd", valid_600891
  var valid_600905 = query.getOrDefault("state")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = newJString("ENABLED"))
  if valid_600905 != nil:
    section.add "state", valid_600905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Content-Sha256", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Algorithm")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Algorithm", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Signature")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Signature", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-SignedHeaders", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Credential")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Credential", valid_600912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600935: Call_GetLifecyclePolicies_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ## 
  let valid = call_600935.validator(path, query, header, formData, body)
  let scheme = call_600935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600935.url(scheme.get, call_600935.host, call_600935.base,
                         call_600935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600935, url, valid)

proc call*(call_601006: Call_GetLifecyclePolicies_600774;
          targetTags: JsonNode = nil; policyIds: JsonNode = nil;
          resourceTypes: JsonNode = nil; tagsToAdd: JsonNode = nil;
          state: string = "ENABLED"): Recallable =
  ## getLifecyclePolicies
  ## <p>Gets summary information about all or the specified data lifecycle policies.</p> <p>To get complete information about a policy, use <a>GetLifecyclePolicy</a>.</p>
  ##   targetTags: JArray
  ##             : <p>The target tag for a policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p>
  ##   policyIds: JArray
  ##            : The identifiers of the data lifecycle policies.
  ##   resourceTypes: JArray
  ##                : The resource type.
  ##   tagsToAdd: JArray
  ##            : <p>The tags to add to objects created by the policy.</p> <p>Tags are strings in the format <code>key=value</code>.</p> <p>These user-defined tags are added in addition to the AWS-added lifecycle tags.</p>
  ##   state: string
  ##        : The activation state.
  var query_601007 = newJObject()
  if targetTags != nil:
    query_601007.add "targetTags", targetTags
  if policyIds != nil:
    query_601007.add "policyIds", policyIds
  if resourceTypes != nil:
    query_601007.add "resourceTypes", resourceTypes
  if tagsToAdd != nil:
    query_601007.add "tagsToAdd", tagsToAdd
  add(query_601007, "state", newJString(state))
  result = call_601006.call(nil, query_601007, nil, nil, nil)

var getLifecyclePolicies* = Call_GetLifecyclePolicies_600774(
    name: "getLifecyclePolicies", meth: HttpMethod.HttpGet,
    host: "dlm.amazonaws.com", route: "/policies",
    validator: validate_GetLifecyclePolicies_600775, base: "/",
    url: url_GetLifecyclePolicies_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_601061 = ref object of OpenApiRestCall_600437
proc url_GetLifecyclePolicy_601063(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetLifecyclePolicy_601062(path: JsonNode; query: JsonNode;
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
  var valid_601078 = path.getOrDefault("policyId")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "policyId", valid_601078
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

proc call*(call_601086: Call_GetLifecyclePolicy_601061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified lifecycle policy.
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_GetLifecyclePolicy_601061; policyId: string): Recallable =
  ## getLifecyclePolicy
  ## Gets detailed information about the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_601088 = newJObject()
  add(path_601088, "policyId", newJString(policyId))
  result = call_601087.call(path_601088, nil, nil, nil, nil)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_601061(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpGet, host: "dlm.amazonaws.com",
    route: "/policies/{policyId}/", validator: validate_GetLifecyclePolicy_601062,
    base: "/", url: url_GetLifecyclePolicy_601063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_601089 = ref object of OpenApiRestCall_600437
proc url_DeleteLifecyclePolicy_601091(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteLifecyclePolicy_601090(path: JsonNode; query: JsonNode;
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
  var valid_601092 = path.getOrDefault("policyId")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = nil)
  if valid_601092 != nil:
    section.add "policyId", valid_601092
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
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_DeleteLifecyclePolicy_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_DeleteLifecyclePolicy_601089; policyId: string): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy and halts the automated operations that the policy specified.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  var path_601102 = newJObject()
  add(path_601102, "policyId", newJString(policyId))
  result = call_601101.call(path_601102, nil, nil, nil, nil)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_601089(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpDelete,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}/",
    validator: validate_DeleteLifecyclePolicy_601090, base: "/",
    url: url_DeleteLifecyclePolicy_601091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLifecyclePolicy_601103 = ref object of OpenApiRestCall_600437
proc url_UpdateLifecyclePolicy_601105(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateLifecyclePolicy_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = path.getOrDefault("policyId")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = nil)
  if valid_601106 != nil:
    section.add "policyId", valid_601106
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
  var valid_601107 = header.getOrDefault("X-Amz-Date")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Date", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Security-Token")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Security-Token", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_UpdateLifecyclePolicy_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified lifecycle policy.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_UpdateLifecyclePolicy_601103; policyId: string;
          body: JsonNode): Recallable =
  ## updateLifecyclePolicy
  ## Updates the specified lifecycle policy.
  ##   policyId: string (required)
  ##           : The identifier of the lifecycle policy.
  ##   body: JObject (required)
  var path_601117 = newJObject()
  var body_601118 = newJObject()
  add(path_601117, "policyId", newJString(policyId))
  if body != nil:
    body_601118 = body
  result = call_601116.call(path_601117, nil, nil, nil, body_601118)

var updateLifecyclePolicy* = Call_UpdateLifecyclePolicy_601103(
    name: "updateLifecyclePolicy", meth: HttpMethod.HttpPatch,
    host: "dlm.amazonaws.com", route: "/policies/{policyId}",
    validator: validate_UpdateLifecyclePolicy_601104, base: "/",
    url: url_UpdateLifecyclePolicy_601105, schemes: {Scheme.Https, Scheme.Http})
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

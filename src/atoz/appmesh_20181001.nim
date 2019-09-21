
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2018-10-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control containerized microservices. App Mesh standardizes how your microservices
##          communicate, giving you end-to-end visibility and helping to ensure high-availability for
##          your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with Amazon ECS
##          (using the Amazon EC2 launch type), Amazon EKS, and Kubernetes on AWS.</p>
##          <note>
##             <p>App Mesh supports containerized microservice applications that use service discovery
##             naming for their components. To use App Mesh, you must have a containerized application
##             running on Amazon EC2 instances, hosted in either Amazon ECS, Amazon EKS, or Kubernetes on AWS. For
##             more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> is supported.
##             For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
##                for Services and Pods</a> in the Kubernetes documentation.</p>
##          </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appmesh/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appmesh.us-west-2.amazonaws.com",
                           "eu-west-2": "appmesh.eu-west-2.amazonaws.com", "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com", "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
                           "us-east-2": "appmesh.us-east-2.amazonaws.com",
                           "us-east-1": "appmesh.us-east-1.amazonaws.com", "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
                           "eu-north-1": "appmesh.eu-north-1.amazonaws.com", "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appmesh.us-west-1.amazonaws.com", "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
                           "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
                           "eu-west-1": "appmesh.eu-west-1.amazonaws.com", "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
      "us-west-2": "appmesh.us-west-2.amazonaws.com",
      "eu-west-2": "appmesh.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
      "us-east-2": "appmesh.us-east-2.amazonaws.com",
      "us-east-1": "appmesh.us-east-1.amazonaws.com",
      "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
      "eu-north-1": "appmesh.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
      "us-west-1": "appmesh.us-west-1.amazonaws.com",
      "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
      "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
      "eu-west-1": "appmesh.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appmesh"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_603027 = ref object of OpenApiRestCall_602433
proc url_CreateMesh_603029(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMesh_603028(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
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
  var valid_603030 = header.getOrDefault("X-Amz-Date")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Date", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Security-Token")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Security-Token", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Content-Sha256", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Algorithm")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Algorithm", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Signature")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Signature", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-SignedHeaders", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Credential")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Credential", valid_603036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603038: Call_CreateMesh_603027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ## 
  let valid = call_603038.validator(path, query, header, formData, body)
  let scheme = call_603038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603038.url(scheme.get, call_603038.host, call_603038.base,
                         call_603038.route, valid.getOrDefault("path"))
  result = hook(call_603038, url, valid)

proc call*(call_603039: Call_CreateMesh_603027; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   body: JObject (required)
  var body_603040 = newJObject()
  if body != nil:
    body_603040 = body
  result = call_603039.call(nil, nil, nil, nil, body_603040)

var createMesh* = Call_CreateMesh_603027(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_CreateMesh_603028,
                                      base: "/", url: url_CreateMesh_603029,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_602770 = ref object of OpenApiRestCall_602433
proc url_ListMeshes_602772(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListMeshes_602771(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing service meshes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_602884 = query.getOrDefault("nextToken")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "nextToken", valid_602884
  var valid_602885 = query.getOrDefault("limit")
  valid_602885 = validateParameter(valid_602885, JInt, required = false, default = nil)
  if valid_602885 != nil:
    section.add "limit", valid_602885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602886 = header.getOrDefault("X-Amz-Date")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Date", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Security-Token")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Security-Token", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Content-Sha256", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Algorithm")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Algorithm", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Signature")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Signature", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-SignedHeaders", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Credential")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Credential", valid_602892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_ListMeshes_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"))
  result = hook(call_602915, url, valid)

proc call*(call_602986: Call_ListMeshes_602770; nextToken: string = ""; limit: int = 0): Recallable =
  ## listMeshes
  ## Returns a list of existing service meshes.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_602987 = newJObject()
  add(query_602987, "nextToken", newJString(nextToken))
  add(query_602987, "limit", newJInt(limit))
  result = call_602986.call(nil, query_602987, nil, nil, nil)

var listMeshes* = Call_ListMeshes_602770(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_ListMeshes_602771,
                                      base: "/", url: url_ListMeshes_602772,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_603073 = ref object of OpenApiRestCall_602433
proc url_CreateRoute_603075(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateRoute_603074(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the route.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603076 = path.getOrDefault("virtualRouterName")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "virtualRouterName", valid_603076
  var valid_603077 = path.getOrDefault("meshName")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = nil)
  if valid_603077 != nil:
    section.add "meshName", valid_603077
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
  var valid_603078 = header.getOrDefault("X-Amz-Date")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Date", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Content-Sha256", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Algorithm")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Algorithm", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Signature")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Signature", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Credential")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Credential", valid_603084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603086: Call_CreateRoute_603073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  let valid = call_603086.validator(path, query, header, formData, body)
  let scheme = call_603086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603086.url(scheme.get, call_603086.host, call_603086.base,
                         call_603086.route, valid.getOrDefault("path"))
  result = hook(call_603086, url, valid)

proc call*(call_603087: Call_CreateRoute_603073; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## createRoute
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the route.
  ##   body: JObject (required)
  var path_603088 = newJObject()
  var body_603089 = newJObject()
  add(path_603088, "virtualRouterName", newJString(virtualRouterName))
  add(path_603088, "meshName", newJString(meshName))
  if body != nil:
    body_603089 = body
  result = call_603087.call(path_603088, nil, nil, nil, body_603089)

var createRoute* = Call_CreateRoute_603073(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_603074,
                                        base: "/", url: url_CreateRoute_603075,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_603041 = ref object of OpenApiRestCall_602433
proc url_ListRoutes_603043(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListRoutes_603042(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to list routes.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list routes.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603058 = path.getOrDefault("virtualRouterName")
  valid_603058 = validateParameter(valid_603058, JString, required = true,
                                 default = nil)
  if valid_603058 != nil:
    section.add "virtualRouterName", valid_603058
  var valid_603059 = path.getOrDefault("meshName")
  valid_603059 = validateParameter(valid_603059, JString, required = true,
                                 default = nil)
  if valid_603059 != nil:
    section.add "meshName", valid_603059
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_603060 = query.getOrDefault("nextToken")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "nextToken", valid_603060
  var valid_603061 = query.getOrDefault("limit")
  valid_603061 = validateParameter(valid_603061, JInt, required = false, default = nil)
  if valid_603061 != nil:
    section.add "limit", valid_603061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603062 = header.getOrDefault("X-Amz-Date")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Date", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Security-Token")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Security-Token", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Content-Sha256", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Algorithm")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Algorithm", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Signature")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Signature", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-SignedHeaders", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Credential")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Credential", valid_603068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603069: Call_ListRoutes_603041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_603069.validator(path, query, header, formData, body)
  let scheme = call_603069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603069.url(scheme.get, call_603069.host, call_603069.base,
                         call_603069.route, valid.getOrDefault("path"))
  result = hook(call_603069, url, valid)

proc call*(call_603070: Call_ListRoutes_603041; virtualRouterName: string;
          meshName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to list routes.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list routes.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var path_603071 = newJObject()
  var query_603072 = newJObject()
  add(path_603071, "virtualRouterName", newJString(virtualRouterName))
  add(path_603071, "meshName", newJString(meshName))
  add(query_603072, "nextToken", newJString(nextToken))
  add(query_603072, "limit", newJInt(limit))
  result = call_603070.call(path_603071, query_603072, nil, nil, nil)

var listRoutes* = Call_ListRoutes_603041(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_603042,
                                      base: "/", url: url_ListRoutes_603043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_603107 = ref object of OpenApiRestCall_602433
proc url_CreateVirtualNode_603109(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateVirtualNode_603108(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the virtual node.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603110 = path.getOrDefault("meshName")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = nil)
  if valid_603110 != nil:
    section.add "meshName", valid_603110
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
  var valid_603111 = header.getOrDefault("X-Amz-Date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Date", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Security-Token")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Security-Token", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Content-Sha256", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Algorithm")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Algorithm", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Credential")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Credential", valid_603117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603119: Call_CreateVirtualNode_603107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  let valid = call_603119.validator(path, query, header, formData, body)
  let scheme = call_603119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603119.url(scheme.get, call_603119.host, call_603119.base,
                         call_603119.route, valid.getOrDefault("path"))
  result = hook(call_603119, url, valid)

proc call*(call_603120: Call_CreateVirtualNode_603107; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualNode
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual node.
  ##   body: JObject (required)
  var path_603121 = newJObject()
  var body_603122 = newJObject()
  add(path_603121, "meshName", newJString(meshName))
  if body != nil:
    body_603122 = body
  result = call_603120.call(path_603121, nil, nil, nil, body_603122)

var createVirtualNode* = Call_CreateVirtualNode_603107(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_603108, base: "/",
    url: url_CreateVirtualNode_603109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_603090 = ref object of OpenApiRestCall_602433
proc url_ListVirtualNodes_603092(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListVirtualNodes_603091(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of existing virtual nodes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603093 = path.getOrDefault("meshName")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "meshName", valid_603093
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_603094 = query.getOrDefault("nextToken")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "nextToken", valid_603094
  var valid_603095 = query.getOrDefault("limit")
  valid_603095 = validateParameter(valid_603095, JInt, required = false, default = nil)
  if valid_603095 != nil:
    section.add "limit", valid_603095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603103: Call_ListVirtualNodes_603090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_603103.validator(path, query, header, formData, body)
  let scheme = call_603103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603103.url(scheme.get, call_603103.host, call_603103.base,
                         call_603103.route, valid.getOrDefault("path"))
  result = hook(call_603103, url, valid)

proc call*(call_603104: Call_ListVirtualNodes_603090; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  var path_603105 = newJObject()
  var query_603106 = newJObject()
  add(path_603105, "meshName", newJString(meshName))
  add(query_603106, "nextToken", newJString(nextToken))
  add(query_603106, "limit", newJInt(limit))
  result = call_603104.call(path_603105, query_603106, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_603090(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_603091, base: "/",
    url: url_ListVirtualNodes_603092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_603140 = ref object of OpenApiRestCall_602433
proc url_CreateVirtualRouter_603142(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateVirtualRouter_603141(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the virtual router.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603143 = path.getOrDefault("meshName")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "meshName", valid_603143
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
  var valid_603144 = header.getOrDefault("X-Amz-Date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Date", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Security-Token")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Security-Token", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Content-Sha256", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Algorithm")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Algorithm", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-SignedHeaders", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Credential")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Credential", valid_603150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603152: Call_CreateVirtualRouter_603140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_603152.validator(path, query, header, formData, body)
  let scheme = call_603152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603152.url(scheme.get, call_603152.host, call_603152.base,
                         call_603152.route, valid.getOrDefault("path"))
  result = hook(call_603152, url, valid)

proc call*(call_603153: Call_CreateVirtualRouter_603140; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual router.
  ##   body: JObject (required)
  var path_603154 = newJObject()
  var body_603155 = newJObject()
  add(path_603154, "meshName", newJString(meshName))
  if body != nil:
    body_603155 = body
  result = call_603153.call(path_603154, nil, nil, nil, body_603155)

var createVirtualRouter* = Call_CreateVirtualRouter_603140(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_603141, base: "/",
    url: url_CreateVirtualRouter_603142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_603123 = ref object of OpenApiRestCall_602433
proc url_ListVirtualRouters_603125(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListVirtualRouters_603124(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to list virtual routers.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603126 = path.getOrDefault("meshName")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "meshName", valid_603126
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_603127 = query.getOrDefault("nextToken")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "nextToken", valid_603127
  var valid_603128 = query.getOrDefault("limit")
  valid_603128 = validateParameter(valid_603128, JInt, required = false, default = nil)
  if valid_603128 != nil:
    section.add "limit", valid_603128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603129 = header.getOrDefault("X-Amz-Date")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Date", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Security-Token")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Security-Token", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Content-Sha256", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Algorithm")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Algorithm", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Signature")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Signature", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-SignedHeaders", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Credential")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Credential", valid_603135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603136: Call_ListVirtualRouters_603123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_603136.validator(path, query, header, formData, body)
  let scheme = call_603136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603136.url(scheme.get, call_603136.host, call_603136.base,
                         call_603136.route, valid.getOrDefault("path"))
  result = hook(call_603136, url, valid)

proc call*(call_603137: Call_ListVirtualRouters_603123; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual routers.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  var path_603138 = newJObject()
  var query_603139 = newJObject()
  add(path_603138, "meshName", newJString(meshName))
  add(query_603139, "nextToken", newJString(nextToken))
  add(query_603139, "limit", newJInt(limit))
  result = call_603137.call(path_603138, query_603139, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_603123(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_603124, base: "/",
    url: url_ListVirtualRouters_603125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_603156 = ref object of OpenApiRestCall_602433
proc url_DescribeMesh_603158(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeMesh_603157(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603159 = path.getOrDefault("meshName")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "meshName", valid_603159
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
  var valid_603160 = header.getOrDefault("X-Amz-Date")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Date", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Security-Token")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Security-Token", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Content-Sha256", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Algorithm")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Algorithm", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Signature")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Signature", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-SignedHeaders", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_DescribeMesh_603156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_DescribeMesh_603156; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_603169 = newJObject()
  add(path_603169, "meshName", newJString(meshName))
  result = call_603168.call(path_603169, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_603156(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_603157, base: "/",
    url: url_DescribeMesh_603158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_603170 = ref object of OpenApiRestCall_602433
proc url_DeleteMesh_603172(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteMesh_603171(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603173 = path.getOrDefault("meshName")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "meshName", valid_603173
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
  var valid_603174 = header.getOrDefault("X-Amz-Date")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Date", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Security-Token")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Security-Token", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Content-Sha256", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Algorithm")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Algorithm", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Signature")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Signature", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-SignedHeaders", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Credential")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Credential", valid_603180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_DeleteMesh_603170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_DeleteMesh_603170; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_603183 = newJObject()
  add(path_603183, "meshName", newJString(meshName))
  result = call_603182.call(path_603183, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_603170(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes/{meshName}",
                                      validator: validate_DeleteMesh_603171,
                                      base: "/", url: url_DeleteMesh_603172,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_603200 = ref object of OpenApiRestCall_602433
proc url_UpdateRoute_603202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateRoute_603201(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603203 = path.getOrDefault("virtualRouterName")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "virtualRouterName", valid_603203
  var valid_603204 = path.getOrDefault("meshName")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "meshName", valid_603204
  var valid_603205 = path.getOrDefault("routeName")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "routeName", valid_603205
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
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Security-Token")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Security-Token", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603214: Call_UpdateRoute_603200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_603214.validator(path, query, header, formData, body)
  let scheme = call_603214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603214.url(scheme.get, call_603214.host, call_603214.base,
                         call_603214.route, valid.getOrDefault("path"))
  result = hook(call_603214, url, valid)

proc call*(call_603215: Call_UpdateRoute_603200; virtualRouterName: string;
          meshName: string; routeName: string; body: JsonNode): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   body: JObject (required)
  var path_603216 = newJObject()
  var body_603217 = newJObject()
  add(path_603216, "virtualRouterName", newJString(virtualRouterName))
  add(path_603216, "meshName", newJString(meshName))
  add(path_603216, "routeName", newJString(routeName))
  if body != nil:
    body_603217 = body
  result = call_603215.call(path_603216, nil, nil, nil, body_603217)

var updateRoute* = Call_UpdateRoute_603200(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_603201,
                                        base: "/", url: url_UpdateRoute_603202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_603184 = ref object of OpenApiRestCall_602433
proc url_DescribeRoute_603186(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeRoute_603185(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603187 = path.getOrDefault("virtualRouterName")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = nil)
  if valid_603187 != nil:
    section.add "virtualRouterName", valid_603187
  var valid_603188 = path.getOrDefault("meshName")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = nil)
  if valid_603188 != nil:
    section.add "meshName", valid_603188
  var valid_603189 = path.getOrDefault("routeName")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "routeName", valid_603189
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
  var valid_603190 = header.getOrDefault("X-Amz-Date")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Date", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Security-Token")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Security-Token", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Content-Sha256", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Algorithm")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Algorithm", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Signature")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Signature", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Credential")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Credential", valid_603196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603197: Call_DescribeRoute_603184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_603197.validator(path, query, header, formData, body)
  let scheme = call_603197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603197.url(scheme.get, call_603197.host, call_603197.base,
                         call_603197.route, valid.getOrDefault("path"))
  result = hook(call_603197, url, valid)

proc call*(call_603198: Call_DescribeRoute_603184; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  var path_603199 = newJObject()
  add(path_603199, "virtualRouterName", newJString(virtualRouterName))
  add(path_603199, "meshName", newJString(meshName))
  add(path_603199, "routeName", newJString(routeName))
  result = call_603198.call(path_603199, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_603184(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_603185, base: "/", url: url_DescribeRoute_603186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_603218 = ref object of OpenApiRestCall_602433
proc url_DeleteRoute_603220(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteRoute_603219(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to delete the route.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603221 = path.getOrDefault("virtualRouterName")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "virtualRouterName", valid_603221
  var valid_603222 = path.getOrDefault("meshName")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "meshName", valid_603222
  var valid_603223 = path.getOrDefault("routeName")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "routeName", valid_603223
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
  var valid_603224 = header.getOrDefault("X-Amz-Date")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Date", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Security-Token")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Security-Token", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Content-Sha256", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Algorithm")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Algorithm", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Signature")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Signature", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-SignedHeaders", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Credential")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Credential", valid_603230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_DeleteRoute_603218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_DeleteRoute_603218; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to delete the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  var path_603233 = newJObject()
  add(path_603233, "virtualRouterName", newJString(virtualRouterName))
  add(path_603233, "meshName", newJString(meshName))
  add(path_603233, "routeName", newJString(routeName))
  result = call_603232.call(path_603233, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_603218(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_603219,
                                        base: "/", url: url_DeleteRoute_603220,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_603249 = ref object of OpenApiRestCall_602433
proc url_UpdateVirtualNode_603251(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateVirtualNode_603250(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603252 = path.getOrDefault("meshName")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "meshName", valid_603252
  var valid_603253 = path.getOrDefault("virtualNodeName")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "virtualNodeName", valid_603253
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
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Content-Sha256", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Algorithm")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Algorithm", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Signature")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Signature", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-SignedHeaders", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Credential")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Credential", valid_603260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603262: Call_UpdateVirtualNode_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_603262.validator(path, query, header, formData, body)
  let scheme = call_603262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603262.url(scheme.get, call_603262.host, call_603262.base,
                         call_603262.route, valid.getOrDefault("path"))
  result = hook(call_603262, url, valid)

proc call*(call_603263: Call_UpdateVirtualNode_603249; meshName: string;
          virtualNodeName: string; body: JsonNode): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  ##   body: JObject (required)
  var path_603264 = newJObject()
  var body_603265 = newJObject()
  add(path_603264, "meshName", newJString(meshName))
  add(path_603264, "virtualNodeName", newJString(virtualNodeName))
  if body != nil:
    body_603265 = body
  result = call_603263.call(path_603264, nil, nil, nil, body_603265)

var updateVirtualNode* = Call_UpdateVirtualNode_603249(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_603250, base: "/",
    url: url_UpdateVirtualNode_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_603234 = ref object of OpenApiRestCall_602433
proc url_DescribeVirtualNode_603236(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeVirtualNode_603235(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603237 = path.getOrDefault("meshName")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "meshName", valid_603237
  var valid_603238 = path.getOrDefault("virtualNodeName")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "virtualNodeName", valid_603238
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
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Credential")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Credential", valid_603245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_DescribeVirtualNode_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_DescribeVirtualNode_603234; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_603248 = newJObject()
  add(path_603248, "meshName", newJString(meshName))
  add(path_603248, "virtualNodeName", newJString(virtualNodeName))
  result = call_603247.call(path_603248, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_603234(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_603235, base: "/",
    url: url_DescribeVirtualNode_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_603266 = ref object of OpenApiRestCall_602433
proc url_DeleteVirtualNode_603268(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVirtualNode_603267(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_603269 = path.getOrDefault("meshName")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "meshName", valid_603269
  var valid_603270 = path.getOrDefault("virtualNodeName")
  valid_603270 = validateParameter(valid_603270, JString, required = true,
                                 default = nil)
  if valid_603270 != nil:
    section.add "virtualNodeName", valid_603270
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
  var valid_603271 = header.getOrDefault("X-Amz-Date")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Date", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Security-Token")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Security-Token", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603278: Call_DeleteVirtualNode_603266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual node.
  ## 
  let valid = call_603278.validator(path, query, header, formData, body)
  let scheme = call_603278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603278.url(scheme.get, call_603278.host, call_603278.base,
                         call_603278.route, valid.getOrDefault("path"))
  result = hook(call_603278, url, valid)

proc call*(call_603279: Call_DeleteVirtualNode_603266; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_603280 = newJObject()
  add(path_603280, "meshName", newJString(meshName))
  add(path_603280, "virtualNodeName", newJString(virtualNodeName))
  result = call_603279.call(path_603280, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_603266(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_603267, base: "/",
    url: url_DeleteVirtualNode_603268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_603296 = ref object of OpenApiRestCall_602433
proc url_UpdateVirtualRouter_603298(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateVirtualRouter_603297(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603299 = path.getOrDefault("virtualRouterName")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "virtualRouterName", valid_603299
  var valid_603300 = path.getOrDefault("meshName")
  valid_603300 = validateParameter(valid_603300, JString, required = true,
                                 default = nil)
  if valid_603300 != nil:
    section.add "meshName", valid_603300
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
  var valid_603301 = header.getOrDefault("X-Amz-Date")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Date", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Security-Token")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Security-Token", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_UpdateVirtualRouter_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_UpdateVirtualRouter_603296; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   body: JObject (required)
  var path_603311 = newJObject()
  var body_603312 = newJObject()
  add(path_603311, "virtualRouterName", newJString(virtualRouterName))
  add(path_603311, "meshName", newJString(meshName))
  if body != nil:
    body_603312 = body
  result = call_603310.call(path_603311, nil, nil, nil, body_603312)

var updateVirtualRouter* = Call_UpdateVirtualRouter_603296(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_603297, base: "/",
    url: url_UpdateVirtualRouter_603298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_603281 = ref object of OpenApiRestCall_602433
proc url_DescribeVirtualRouter_603283(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeVirtualRouter_603282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603284 = path.getOrDefault("virtualRouterName")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "virtualRouterName", valid_603284
  var valid_603285 = path.getOrDefault("meshName")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = nil)
  if valid_603285 != nil:
    section.add "meshName", valid_603285
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
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_DescribeVirtualRouter_603281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"))
  result = hook(call_603293, url, valid)

proc call*(call_603294: Call_DescribeVirtualRouter_603281;
          virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  var path_603295 = newJObject()
  add(path_603295, "virtualRouterName", newJString(virtualRouterName))
  add(path_603295, "meshName", newJString(meshName))
  result = call_603294.call(path_603295, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_603281(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_603282, base: "/",
    url: url_DescribeVirtualRouter_603283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_603313 = ref object of OpenApiRestCall_602433
proc url_DeleteVirtualRouter_603315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVirtualRouter_603314(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_603316 = path.getOrDefault("virtualRouterName")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = nil)
  if valid_603316 != nil:
    section.add "virtualRouterName", valid_603316
  var valid_603317 = path.getOrDefault("meshName")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = nil)
  if valid_603317 != nil:
    section.add "meshName", valid_603317
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
  var valid_603318 = header.getOrDefault("X-Amz-Date")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Date", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Security-Token")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Security-Token", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Content-Sha256", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Algorithm")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Algorithm", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Signature")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Signature", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-SignedHeaders", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Credential")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Credential", valid_603324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_DeleteVirtualRouter_603313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_DeleteVirtualRouter_603313; virtualRouterName: string;
          meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  var path_603327 = newJObject()
  add(path_603327, "virtualRouterName", newJString(virtualRouterName))
  add(path_603327, "meshName", newJString(meshName))
  result = call_603326.call(path_603327, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_603313(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_603314, base: "/",
    url: url_DeleteVirtualRouter_603315, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

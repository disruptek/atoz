
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
  Call_CreateMesh_773190 = ref object of OpenApiRestCall_772597
proc url_CreateMesh_773192(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMesh_773191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773193 = header.getOrDefault("X-Amz-Date")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Date", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Security-Token")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Security-Token", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Content-Sha256", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Algorithm")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Algorithm", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Signature")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Signature", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-SignedHeaders", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Credential")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Credential", valid_773199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773201: Call_CreateMesh_773190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ## 
  let valid = call_773201.validator(path, query, header, formData, body)
  let scheme = call_773201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773201.url(scheme.get, call_773201.host, call_773201.base,
                         call_773201.route, valid.getOrDefault("path"))
  result = hook(call_773201, url, valid)

proc call*(call_773202: Call_CreateMesh_773190; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   body: JObject (required)
  var body_773203 = newJObject()
  if body != nil:
    body_773203 = body
  result = call_773202.call(nil, nil, nil, nil, body_773203)

var createMesh* = Call_CreateMesh_773190(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_CreateMesh_773191,
                                      base: "/", url: url_CreateMesh_773192,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_772933 = ref object of OpenApiRestCall_772597
proc url_ListMeshes_772935(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListMeshes_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773047 = query.getOrDefault("nextToken")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "nextToken", valid_773047
  var valid_773048 = query.getOrDefault("limit")
  valid_773048 = validateParameter(valid_773048, JInt, required = false, default = nil)
  if valid_773048 != nil:
    section.add "limit", valid_773048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773049 = header.getOrDefault("X-Amz-Date")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Date", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Security-Token")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Security-Token", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Content-Sha256", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Algorithm")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Algorithm", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Signature")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Signature", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-SignedHeaders", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Credential")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Credential", valid_773055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773078: Call_ListMeshes_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_773078.validator(path, query, header, formData, body)
  let scheme = call_773078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773078.url(scheme.get, call_773078.host, call_773078.base,
                         call_773078.route, valid.getOrDefault("path"))
  result = hook(call_773078, url, valid)

proc call*(call_773149: Call_ListMeshes_772933; nextToken: string = ""; limit: int = 0): Recallable =
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
  var query_773150 = newJObject()
  add(query_773150, "nextToken", newJString(nextToken))
  add(query_773150, "limit", newJInt(limit))
  result = call_773149.call(nil, query_773150, nil, nil, nil)

var listMeshes* = Call_ListMeshes_772933(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
                                      validator: validate_ListMeshes_772934,
                                      base: "/", url: url_ListMeshes_772935,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_773236 = ref object of OpenApiRestCall_772597
proc url_CreateRoute_773238(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateRoute_773237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773239 = path.getOrDefault("virtualRouterName")
  valid_773239 = validateParameter(valid_773239, JString, required = true,
                                 default = nil)
  if valid_773239 != nil:
    section.add "virtualRouterName", valid_773239
  var valid_773240 = path.getOrDefault("meshName")
  valid_773240 = validateParameter(valid_773240, JString, required = true,
                                 default = nil)
  if valid_773240 != nil:
    section.add "meshName", valid_773240
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
  var valid_773241 = header.getOrDefault("X-Amz-Date")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Date", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Security-Token")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Security-Token", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Content-Sha256", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Algorithm")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Algorithm", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Signature")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Signature", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-SignedHeaders", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Credential")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Credential", valid_773247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773249: Call_CreateRoute_773236; path: JsonNode; query: JsonNode;
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
  let valid = call_773249.validator(path, query, header, formData, body)
  let scheme = call_773249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773249.url(scheme.get, call_773249.host, call_773249.base,
                         call_773249.route, valid.getOrDefault("path"))
  result = hook(call_773249, url, valid)

proc call*(call_773250: Call_CreateRoute_773236; virtualRouterName: string;
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
  var path_773251 = newJObject()
  var body_773252 = newJObject()
  add(path_773251, "virtualRouterName", newJString(virtualRouterName))
  add(path_773251, "meshName", newJString(meshName))
  if body != nil:
    body_773252 = body
  result = call_773250.call(path_773251, nil, nil, nil, body_773252)

var createRoute* = Call_CreateRoute_773236(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_773237,
                                        base: "/", url: url_CreateRoute_773238,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_773204 = ref object of OpenApiRestCall_772597
proc url_ListRoutes_773206(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListRoutes_773205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773221 = path.getOrDefault("virtualRouterName")
  valid_773221 = validateParameter(valid_773221, JString, required = true,
                                 default = nil)
  if valid_773221 != nil:
    section.add "virtualRouterName", valid_773221
  var valid_773222 = path.getOrDefault("meshName")
  valid_773222 = validateParameter(valid_773222, JString, required = true,
                                 default = nil)
  if valid_773222 != nil:
    section.add "meshName", valid_773222
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
  var valid_773223 = query.getOrDefault("nextToken")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "nextToken", valid_773223
  var valid_773224 = query.getOrDefault("limit")
  valid_773224 = validateParameter(valid_773224, JInt, required = false, default = nil)
  if valid_773224 != nil:
    section.add "limit", valid_773224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773225 = header.getOrDefault("X-Amz-Date")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Date", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Security-Token")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Security-Token", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Content-Sha256", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Algorithm")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Algorithm", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Signature")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Signature", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-SignedHeaders", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Credential")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Credential", valid_773231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773232: Call_ListRoutes_773204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_773232.validator(path, query, header, formData, body)
  let scheme = call_773232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773232.url(scheme.get, call_773232.host, call_773232.base,
                         call_773232.route, valid.getOrDefault("path"))
  result = hook(call_773232, url, valid)

proc call*(call_773233: Call_ListRoutes_773204; virtualRouterName: string;
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
  var path_773234 = newJObject()
  var query_773235 = newJObject()
  add(path_773234, "virtualRouterName", newJString(virtualRouterName))
  add(path_773234, "meshName", newJString(meshName))
  add(query_773235, "nextToken", newJString(nextToken))
  add(query_773235, "limit", newJInt(limit))
  result = call_773233.call(path_773234, query_773235, nil, nil, nil)

var listRoutes* = Call_ListRoutes_773204(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_773205,
                                      base: "/", url: url_ListRoutes_773206,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_773270 = ref object of OpenApiRestCall_772597
proc url_CreateVirtualNode_773272(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateVirtualNode_773271(path: JsonNode; query: JsonNode;
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
  var valid_773273 = path.getOrDefault("meshName")
  valid_773273 = validateParameter(valid_773273, JString, required = true,
                                 default = nil)
  if valid_773273 != nil:
    section.add "meshName", valid_773273
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
  var valid_773274 = header.getOrDefault("X-Amz-Date")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Date", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Security-Token")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Security-Token", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Content-Sha256", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Algorithm")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Algorithm", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Signature")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Signature", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-SignedHeaders", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Credential")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Credential", valid_773280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773282: Call_CreateVirtualNode_773270; path: JsonNode;
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
  let valid = call_773282.validator(path, query, header, formData, body)
  let scheme = call_773282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773282.url(scheme.get, call_773282.host, call_773282.base,
                         call_773282.route, valid.getOrDefault("path"))
  result = hook(call_773282, url, valid)

proc call*(call_773283: Call_CreateVirtualNode_773270; meshName: string;
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
  var path_773284 = newJObject()
  var body_773285 = newJObject()
  add(path_773284, "meshName", newJString(meshName))
  if body != nil:
    body_773285 = body
  result = call_773283.call(path_773284, nil, nil, nil, body_773285)

var createVirtualNode* = Call_CreateVirtualNode_773270(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_773271, base: "/",
    url: url_CreateVirtualNode_773272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_773253 = ref object of OpenApiRestCall_772597
proc url_ListVirtualNodes_773255(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListVirtualNodes_773254(path: JsonNode; query: JsonNode;
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
  var valid_773256 = path.getOrDefault("meshName")
  valid_773256 = validateParameter(valid_773256, JString, required = true,
                                 default = nil)
  if valid_773256 != nil:
    section.add "meshName", valid_773256
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
  var valid_773257 = query.getOrDefault("nextToken")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "nextToken", valid_773257
  var valid_773258 = query.getOrDefault("limit")
  valid_773258 = validateParameter(valid_773258, JInt, required = false, default = nil)
  if valid_773258 != nil:
    section.add "limit", valid_773258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773259 = header.getOrDefault("X-Amz-Date")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Date", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Security-Token")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Security-Token", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Content-Sha256", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Algorithm")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Algorithm", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Signature")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Signature", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-SignedHeaders", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Credential")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Credential", valid_773265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773266: Call_ListVirtualNodes_773253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_773266.validator(path, query, header, formData, body)
  let scheme = call_773266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773266.url(scheme.get, call_773266.host, call_773266.base,
                         call_773266.route, valid.getOrDefault("path"))
  result = hook(call_773266, url, valid)

proc call*(call_773267: Call_ListVirtualNodes_773253; meshName: string;
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
  var path_773268 = newJObject()
  var query_773269 = newJObject()
  add(path_773268, "meshName", newJString(meshName))
  add(query_773269, "nextToken", newJString(nextToken))
  add(query_773269, "limit", newJInt(limit))
  result = call_773267.call(path_773268, query_773269, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_773253(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_773254, base: "/",
    url: url_ListVirtualNodes_773255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_773303 = ref object of OpenApiRestCall_772597
proc url_CreateVirtualRouter_773305(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateVirtualRouter_773304(path: JsonNode; query: JsonNode;
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
  var valid_773306 = path.getOrDefault("meshName")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = nil)
  if valid_773306 != nil:
    section.add "meshName", valid_773306
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
  var valid_773307 = header.getOrDefault("X-Amz-Date")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Date", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Security-Token")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Security-Token", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Content-Sha256", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Algorithm")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Algorithm", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Signature")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Signature", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-SignedHeaders", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Credential")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Credential", valid_773313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773315: Call_CreateVirtualRouter_773303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_773315.validator(path, query, header, formData, body)
  let scheme = call_773315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773315.url(scheme.get, call_773315.host, call_773315.base,
                         call_773315.route, valid.getOrDefault("path"))
  result = hook(call_773315, url, valid)

proc call*(call_773316: Call_CreateVirtualRouter_773303; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual router.
  ##   body: JObject (required)
  var path_773317 = newJObject()
  var body_773318 = newJObject()
  add(path_773317, "meshName", newJString(meshName))
  if body != nil:
    body_773318 = body
  result = call_773316.call(path_773317, nil, nil, nil, body_773318)

var createVirtualRouter* = Call_CreateVirtualRouter_773303(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_773304, base: "/",
    url: url_CreateVirtualRouter_773305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_773286 = ref object of OpenApiRestCall_772597
proc url_ListVirtualRouters_773288(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListVirtualRouters_773287(path: JsonNode; query: JsonNode;
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
  var valid_773289 = path.getOrDefault("meshName")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = nil)
  if valid_773289 != nil:
    section.add "meshName", valid_773289
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
  var valid_773290 = query.getOrDefault("nextToken")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "nextToken", valid_773290
  var valid_773291 = query.getOrDefault("limit")
  valid_773291 = validateParameter(valid_773291, JInt, required = false, default = nil)
  if valid_773291 != nil:
    section.add "limit", valid_773291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773292 = header.getOrDefault("X-Amz-Date")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Date", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Security-Token")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Security-Token", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Content-Sha256", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Algorithm")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Algorithm", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Signature")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Signature", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-SignedHeaders", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Credential")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Credential", valid_773298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773299: Call_ListVirtualRouters_773286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_773299.validator(path, query, header, formData, body)
  let scheme = call_773299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773299.url(scheme.get, call_773299.host, call_773299.base,
                         call_773299.route, valid.getOrDefault("path"))
  result = hook(call_773299, url, valid)

proc call*(call_773300: Call_ListVirtualRouters_773286; meshName: string;
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
  var path_773301 = newJObject()
  var query_773302 = newJObject()
  add(path_773301, "meshName", newJString(meshName))
  add(query_773302, "nextToken", newJString(nextToken))
  add(query_773302, "limit", newJInt(limit))
  result = call_773300.call(path_773301, query_773302, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_773286(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_773287, base: "/",
    url: url_ListVirtualRouters_773288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_773319 = ref object of OpenApiRestCall_772597
proc url_DescribeMesh_773321(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeMesh_773320(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773322 = path.getOrDefault("meshName")
  valid_773322 = validateParameter(valid_773322, JString, required = true,
                                 default = nil)
  if valid_773322 != nil:
    section.add "meshName", valid_773322
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
  var valid_773323 = header.getOrDefault("X-Amz-Date")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Date", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Security-Token")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Security-Token", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Content-Sha256", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Algorithm")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Algorithm", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Signature")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Signature", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-SignedHeaders", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Credential")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Credential", valid_773329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773330: Call_DescribeMesh_773319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_773330.validator(path, query, header, formData, body)
  let scheme = call_773330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773330.url(scheme.get, call_773330.host, call_773330.base,
                         call_773330.route, valid.getOrDefault("path"))
  result = hook(call_773330, url, valid)

proc call*(call_773331: Call_DescribeMesh_773319; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_773332 = newJObject()
  add(path_773332, "meshName", newJString(meshName))
  result = call_773331.call(path_773332, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_773319(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_773320, base: "/",
    url: url_DescribeMesh_773321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_773333 = ref object of OpenApiRestCall_772597
proc url_DeleteMesh_773335(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMesh_773334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773336 = path.getOrDefault("meshName")
  valid_773336 = validateParameter(valid_773336, JString, required = true,
                                 default = nil)
  if valid_773336 != nil:
    section.add "meshName", valid_773336
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
  var valid_773337 = header.getOrDefault("X-Amz-Date")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Date", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Security-Token")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Security-Token", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Content-Sha256", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Algorithm")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Algorithm", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Signature")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Signature", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-SignedHeaders", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Credential")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Credential", valid_773343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773344: Call_DeleteMesh_773333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_773344.validator(path, query, header, formData, body)
  let scheme = call_773344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773344.url(scheme.get, call_773344.host, call_773344.base,
                         call_773344.route, valid.getOrDefault("path"))
  result = hook(call_773344, url, valid)

proc call*(call_773345: Call_DeleteMesh_773333; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_773346 = newJObject()
  add(path_773346, "meshName", newJString(meshName))
  result = call_773345.call(path_773346, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_773333(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes/{meshName}",
                                      validator: validate_DeleteMesh_773334,
                                      base: "/", url: url_DeleteMesh_773335,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_773363 = ref object of OpenApiRestCall_772597
proc url_UpdateRoute_773365(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRoute_773364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773366 = path.getOrDefault("virtualRouterName")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "virtualRouterName", valid_773366
  var valid_773367 = path.getOrDefault("meshName")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = nil)
  if valid_773367 != nil:
    section.add "meshName", valid_773367
  var valid_773368 = path.getOrDefault("routeName")
  valid_773368 = validateParameter(valid_773368, JString, required = true,
                                 default = nil)
  if valid_773368 != nil:
    section.add "routeName", valid_773368
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
  var valid_773369 = header.getOrDefault("X-Amz-Date")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Date", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Security-Token")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Security-Token", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Content-Sha256", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Algorithm")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Algorithm", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Signature")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Signature", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-SignedHeaders", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Credential")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Credential", valid_773375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773377: Call_UpdateRoute_773363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_773377.validator(path, query, header, formData, body)
  let scheme = call_773377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773377.url(scheme.get, call_773377.host, call_773377.base,
                         call_773377.route, valid.getOrDefault("path"))
  result = hook(call_773377, url, valid)

proc call*(call_773378: Call_UpdateRoute_773363; virtualRouterName: string;
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
  var path_773379 = newJObject()
  var body_773380 = newJObject()
  add(path_773379, "virtualRouterName", newJString(virtualRouterName))
  add(path_773379, "meshName", newJString(meshName))
  add(path_773379, "routeName", newJString(routeName))
  if body != nil:
    body_773380 = body
  result = call_773378.call(path_773379, nil, nil, nil, body_773380)

var updateRoute* = Call_UpdateRoute_773363(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_773364,
                                        base: "/", url: url_UpdateRoute_773365,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_773347 = ref object of OpenApiRestCall_772597
proc url_DescribeRoute_773349(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeRoute_773348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773350 = path.getOrDefault("virtualRouterName")
  valid_773350 = validateParameter(valid_773350, JString, required = true,
                                 default = nil)
  if valid_773350 != nil:
    section.add "virtualRouterName", valid_773350
  var valid_773351 = path.getOrDefault("meshName")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "meshName", valid_773351
  var valid_773352 = path.getOrDefault("routeName")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = nil)
  if valid_773352 != nil:
    section.add "routeName", valid_773352
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
  var valid_773353 = header.getOrDefault("X-Amz-Date")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Date", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Security-Token")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Security-Token", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Content-Sha256", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Algorithm")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Algorithm", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Signature")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Signature", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-SignedHeaders", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Credential")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Credential", valid_773359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773360: Call_DescribeRoute_773347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_773360.validator(path, query, header, formData, body)
  let scheme = call_773360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773360.url(scheme.get, call_773360.host, call_773360.base,
                         call_773360.route, valid.getOrDefault("path"))
  result = hook(call_773360, url, valid)

proc call*(call_773361: Call_DescribeRoute_773347; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  var path_773362 = newJObject()
  add(path_773362, "virtualRouterName", newJString(virtualRouterName))
  add(path_773362, "meshName", newJString(meshName))
  add(path_773362, "routeName", newJString(routeName))
  result = call_773361.call(path_773362, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_773347(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_773348, base: "/", url: url_DescribeRoute_773349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_773381 = ref object of OpenApiRestCall_772597
proc url_DeleteRoute_773383(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRoute_773382(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773384 = path.getOrDefault("virtualRouterName")
  valid_773384 = validateParameter(valid_773384, JString, required = true,
                                 default = nil)
  if valid_773384 != nil:
    section.add "virtualRouterName", valid_773384
  var valid_773385 = path.getOrDefault("meshName")
  valid_773385 = validateParameter(valid_773385, JString, required = true,
                                 default = nil)
  if valid_773385 != nil:
    section.add "meshName", valid_773385
  var valid_773386 = path.getOrDefault("routeName")
  valid_773386 = validateParameter(valid_773386, JString, required = true,
                                 default = nil)
  if valid_773386 != nil:
    section.add "routeName", valid_773386
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
  var valid_773387 = header.getOrDefault("X-Amz-Date")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Date", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Security-Token")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Security-Token", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Content-Sha256", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Algorithm")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Algorithm", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Signature")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Signature", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-SignedHeaders", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Credential")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Credential", valid_773393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_DeleteRoute_773381; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_DeleteRoute_773381; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to delete the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  var path_773396 = newJObject()
  add(path_773396, "virtualRouterName", newJString(virtualRouterName))
  add(path_773396, "meshName", newJString(meshName))
  add(path_773396, "routeName", newJString(routeName))
  result = call_773395.call(path_773396, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_773381(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_773382,
                                        base: "/", url: url_DeleteRoute_773383,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_773412 = ref object of OpenApiRestCall_772597
proc url_UpdateVirtualNode_773414(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVirtualNode_773413(path: JsonNode; query: JsonNode;
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
  var valid_773415 = path.getOrDefault("meshName")
  valid_773415 = validateParameter(valid_773415, JString, required = true,
                                 default = nil)
  if valid_773415 != nil:
    section.add "meshName", valid_773415
  var valid_773416 = path.getOrDefault("virtualNodeName")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = nil)
  if valid_773416 != nil:
    section.add "virtualNodeName", valid_773416
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
  var valid_773417 = header.getOrDefault("X-Amz-Date")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Date", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Security-Token")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Security-Token", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Content-Sha256", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Algorithm")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Algorithm", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Signature")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Signature", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-SignedHeaders", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Credential")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Credential", valid_773423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773425: Call_UpdateVirtualNode_773412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_773425.validator(path, query, header, formData, body)
  let scheme = call_773425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773425.url(scheme.get, call_773425.host, call_773425.base,
                         call_773425.route, valid.getOrDefault("path"))
  result = hook(call_773425, url, valid)

proc call*(call_773426: Call_UpdateVirtualNode_773412; meshName: string;
          virtualNodeName: string; body: JsonNode): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  ##   body: JObject (required)
  var path_773427 = newJObject()
  var body_773428 = newJObject()
  add(path_773427, "meshName", newJString(meshName))
  add(path_773427, "virtualNodeName", newJString(virtualNodeName))
  if body != nil:
    body_773428 = body
  result = call_773426.call(path_773427, nil, nil, nil, body_773428)

var updateVirtualNode* = Call_UpdateVirtualNode_773412(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_773413, base: "/",
    url: url_UpdateVirtualNode_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_773397 = ref object of OpenApiRestCall_772597
proc url_DescribeVirtualNode_773399(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeVirtualNode_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = path.getOrDefault("meshName")
  valid_773400 = validateParameter(valid_773400, JString, required = true,
                                 default = nil)
  if valid_773400 != nil:
    section.add "meshName", valid_773400
  var valid_773401 = path.getOrDefault("virtualNodeName")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = nil)
  if valid_773401 != nil:
    section.add "virtualNodeName", valid_773401
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
  var valid_773402 = header.getOrDefault("X-Amz-Date")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Date", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Security-Token")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Security-Token", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Content-Sha256", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Algorithm")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Algorithm", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Signature")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Signature", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-SignedHeaders", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Credential")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Credential", valid_773408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_DescribeVirtualNode_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_DescribeVirtualNode_773397; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_773411 = newJObject()
  add(path_773411, "meshName", newJString(meshName))
  add(path_773411, "virtualNodeName", newJString(virtualNodeName))
  result = call_773410.call(path_773411, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_773397(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_773398, base: "/",
    url: url_DescribeVirtualNode_773399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_773429 = ref object of OpenApiRestCall_772597
proc url_DeleteVirtualNode_773431(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVirtualNode_773430(path: JsonNode; query: JsonNode;
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
  var valid_773432 = path.getOrDefault("meshName")
  valid_773432 = validateParameter(valid_773432, JString, required = true,
                                 default = nil)
  if valid_773432 != nil:
    section.add "meshName", valid_773432
  var valid_773433 = path.getOrDefault("virtualNodeName")
  valid_773433 = validateParameter(valid_773433, JString, required = true,
                                 default = nil)
  if valid_773433 != nil:
    section.add "virtualNodeName", valid_773433
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
  var valid_773434 = header.getOrDefault("X-Amz-Date")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Date", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Security-Token")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Security-Token", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Content-Sha256", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Algorithm")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Algorithm", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Signature")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Signature", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-SignedHeaders", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Credential")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Credential", valid_773440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773441: Call_DeleteVirtualNode_773429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual node.
  ## 
  let valid = call_773441.validator(path, query, header, formData, body)
  let scheme = call_773441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773441.url(scheme.get, call_773441.host, call_773441.base,
                         call_773441.route, valid.getOrDefault("path"))
  result = hook(call_773441, url, valid)

proc call*(call_773442: Call_DeleteVirtualNode_773429; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_773443 = newJObject()
  add(path_773443, "meshName", newJString(meshName))
  add(path_773443, "virtualNodeName", newJString(virtualNodeName))
  result = call_773442.call(path_773443, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_773429(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_773430, base: "/",
    url: url_DeleteVirtualNode_773431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_773459 = ref object of OpenApiRestCall_772597
proc url_UpdateVirtualRouter_773461(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVirtualRouter_773460(path: JsonNode; query: JsonNode;
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
  var valid_773462 = path.getOrDefault("virtualRouterName")
  valid_773462 = validateParameter(valid_773462, JString, required = true,
                                 default = nil)
  if valid_773462 != nil:
    section.add "virtualRouterName", valid_773462
  var valid_773463 = path.getOrDefault("meshName")
  valid_773463 = validateParameter(valid_773463, JString, required = true,
                                 default = nil)
  if valid_773463 != nil:
    section.add "meshName", valid_773463
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
  var valid_773464 = header.getOrDefault("X-Amz-Date")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Date", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Security-Token")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Security-Token", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Content-Sha256", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Algorithm")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Algorithm", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Signature")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Signature", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-SignedHeaders", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Credential")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Credential", valid_773470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773472: Call_UpdateVirtualRouter_773459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_773472.validator(path, query, header, formData, body)
  let scheme = call_773472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773472.url(scheme.get, call_773472.host, call_773472.base,
                         call_773472.route, valid.getOrDefault("path"))
  result = hook(call_773472, url, valid)

proc call*(call_773473: Call_UpdateVirtualRouter_773459; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   body: JObject (required)
  var path_773474 = newJObject()
  var body_773475 = newJObject()
  add(path_773474, "virtualRouterName", newJString(virtualRouterName))
  add(path_773474, "meshName", newJString(meshName))
  if body != nil:
    body_773475 = body
  result = call_773473.call(path_773474, nil, nil, nil, body_773475)

var updateVirtualRouter* = Call_UpdateVirtualRouter_773459(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_773460, base: "/",
    url: url_UpdateVirtualRouter_773461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_773444 = ref object of OpenApiRestCall_772597
proc url_DescribeVirtualRouter_773446(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeVirtualRouter_773445(path: JsonNode; query: JsonNode;
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
  var valid_773447 = path.getOrDefault("virtualRouterName")
  valid_773447 = validateParameter(valid_773447, JString, required = true,
                                 default = nil)
  if valid_773447 != nil:
    section.add "virtualRouterName", valid_773447
  var valid_773448 = path.getOrDefault("meshName")
  valid_773448 = validateParameter(valid_773448, JString, required = true,
                                 default = nil)
  if valid_773448 != nil:
    section.add "meshName", valid_773448
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
  var valid_773449 = header.getOrDefault("X-Amz-Date")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Date", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Security-Token")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Security-Token", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Content-Sha256", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Algorithm")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Algorithm", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Signature")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Signature", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-SignedHeaders", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Credential")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Credential", valid_773455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773456: Call_DescribeVirtualRouter_773444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_773456.validator(path, query, header, formData, body)
  let scheme = call_773456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773456.url(scheme.get, call_773456.host, call_773456.base,
                         call_773456.route, valid.getOrDefault("path"))
  result = hook(call_773456, url, valid)

proc call*(call_773457: Call_DescribeVirtualRouter_773444;
          virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  var path_773458 = newJObject()
  add(path_773458, "virtualRouterName", newJString(virtualRouterName))
  add(path_773458, "meshName", newJString(meshName))
  result = call_773457.call(path_773458, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_773444(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_773445, base: "/",
    url: url_DescribeVirtualRouter_773446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_773476 = ref object of OpenApiRestCall_772597
proc url_DeleteVirtualRouter_773478(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVirtualRouter_773477(path: JsonNode; query: JsonNode;
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
  var valid_773479 = path.getOrDefault("virtualRouterName")
  valid_773479 = validateParameter(valid_773479, JString, required = true,
                                 default = nil)
  if valid_773479 != nil:
    section.add "virtualRouterName", valid_773479
  var valid_773480 = path.getOrDefault("meshName")
  valid_773480 = validateParameter(valid_773480, JString, required = true,
                                 default = nil)
  if valid_773480 != nil:
    section.add "meshName", valid_773480
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
  var valid_773481 = header.getOrDefault("X-Amz-Date")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Date", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Security-Token")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Security-Token", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Content-Sha256", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Algorithm")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Algorithm", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Signature")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Signature", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-SignedHeaders", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Credential")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Credential", valid_773487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773488: Call_DeleteVirtualRouter_773476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_773488.validator(path, query, header, formData, body)
  let scheme = call_773488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773488.url(scheme.get, call_773488.host, call_773488.base,
                         call_773488.route, valid.getOrDefault("path"))
  result = hook(call_773488, url, valid)

proc call*(call_773489: Call_DeleteVirtualRouter_773476; virtualRouterName: string;
          meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  var path_773490 = newJObject()
  add(path_773490, "virtualRouterName", newJString(virtualRouterName))
  add(path_773490, "meshName", newJString(meshName))
  result = call_773489.call(path_773490, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_773476(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_773477, base: "/",
    url: url_DeleteVirtualRouter_773478, schemes: {Scheme.Https, Scheme.Http})
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

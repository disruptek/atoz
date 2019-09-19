
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2019-01-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control microservices. App Mesh standardizes how your microservices communicate, giving you
##          end-to-end visibility and helping to ensure high availability for your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with AWS Fargate, Amazon ECS, Amazon EKS,
##          Kubernetes on AWS, and Amazon EC2.</p>
##          <note>
##             <p>App Mesh supports microservice applications that use service discovery naming for their
##             components. For more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> and
##                <code>coredns</code> are supported. For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
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
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
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
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
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
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_773203 = newJObject()
  if body != nil:
    body_773203 = body
  result = call_773202.call(nil, nil, nil, nil, body_773203)

var createMesh* = Call_CreateMesh_773190(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
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
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
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
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_773150 = newJObject()
  add(query_773150, "nextToken", newJString(nextToken))
  add(query_773150, "limit", newJInt(limit))
  result = call_773149.call(nil, query_773150, nil, nil, nil)

var listMeshes* = Call_ListMeshes_772933(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
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
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
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
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
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
  ##           : The name of the service mesh to create the route in.
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
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
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
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the route in.
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
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
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
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
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
  ##                    : The name of the virtual router to list routes in.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list routes in.
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
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
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
  ##                    : The name of the virtual router to list routes in.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list routes in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
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
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
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
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateVirtualNode_773271(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
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
  ##           : The name of the service mesh to create the virtual node in.
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
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
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
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
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
  ##           : The name of the service mesh to create the virtual node in.
  ##   body: JObject (required)
  var path_773284 = newJObject()
  var body_773285 = newJObject()
  add(path_773284, "meshName", newJString(meshName))
  if body != nil:
    body_773285 = body
  result = call_773283.call(path_773284, nil, nil, nil, body_773285)

var createVirtualNode* = Call_CreateVirtualNode_773270(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_773271, base: "/",
    url: url_CreateVirtualNode_773272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_773253 = ref object of OpenApiRestCall_772597
proc url_ListVirtualNodes_773255(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
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
  ##           : The name of the service mesh to list virtual nodes in.
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
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
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
  ##           : The name of the service mesh to list virtual nodes in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var path_773268 = newJObject()
  var query_773269 = newJObject()
  add(path_773268, "meshName", newJString(meshName))
  add(query_773269, "nextToken", newJString(nextToken))
  add(query_773269, "limit", newJInt(limit))
  result = call_773267.call(path_773268, query_773269, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_773253(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_773254, base: "/",
    url: url_ListVirtualNodes_773255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_773303 = ref object of OpenApiRestCall_772597
proc url_CreateVirtualRouter_773305(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateVirtualRouter_773304(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual router in.
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
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
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
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual router in.
  ##   body: JObject (required)
  var path_773317 = newJObject()
  var body_773318 = newJObject()
  add(path_773317, "meshName", newJString(meshName))
  if body != nil:
    body_773318 = body
  result = call_773316.call(path_773317, nil, nil, nil, body_773318)

var createVirtualRouter* = Call_CreateVirtualRouter_773303(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_773304, base: "/",
    url: url_CreateVirtualRouter_773305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_773286 = ref object of OpenApiRestCall_772597
proc url_ListVirtualRouters_773288(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
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
  ##           : The name of the service mesh to list virtual routers in.
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
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
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
  ##           : The name of the service mesh to list virtual routers in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  var path_773301 = newJObject()
  var query_773302 = newJObject()
  add(path_773301, "meshName", newJString(meshName))
  add(query_773302, "nextToken", newJString(nextToken))
  add(query_773302, "limit", newJInt(limit))
  result = call_773300.call(path_773301, query_773302, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_773286(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_773287, base: "/",
    url: url_ListVirtualRouters_773288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_773336 = ref object of OpenApiRestCall_772597
proc url_CreateVirtualService_773338(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateVirtualService_773337(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual service in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773339 = path.getOrDefault("meshName")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "meshName", valid_773339
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Content-Sha256", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Algorithm")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Algorithm", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Signature")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Signature", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-SignedHeaders", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Credential")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Credential", valid_773346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_CreateVirtualService_773336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_CreateVirtualService_773336; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualService
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual service in.
  ##   body: JObject (required)
  var path_773350 = newJObject()
  var body_773351 = newJObject()
  add(path_773350, "meshName", newJString(meshName))
  if body != nil:
    body_773351 = body
  result = call_773349.call(path_773350, nil, nil, nil, body_773351)

var createVirtualService* = Call_CreateVirtualService_773336(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_773337, base: "/",
    url: url_CreateVirtualService_773338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_773319 = ref object of OpenApiRestCall_772597
proc url_ListVirtualServices_773321(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListVirtualServices_773320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual services in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773322 = path.getOrDefault("meshName")
  valid_773322 = validateParameter(valid_773322, JString, required = true,
                                 default = nil)
  if valid_773322 != nil:
    section.add "meshName", valid_773322
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_773323 = query.getOrDefault("nextToken")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "nextToken", valid_773323
  var valid_773324 = query.getOrDefault("limit")
  valid_773324 = validateParameter(valid_773324, JInt, required = false, default = nil)
  if valid_773324 != nil:
    section.add "limit", valid_773324
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Content-Sha256", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Algorithm")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Algorithm", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Signature")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Signature", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-SignedHeaders", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Credential")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Credential", valid_773331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773332: Call_ListVirtualServices_773319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_773332.validator(path, query, header, formData, body)
  let scheme = call_773332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773332.url(scheme.get, call_773332.host, call_773332.base,
                         call_773332.route, valid.getOrDefault("path"))
  result = hook(call_773332, url, valid)

proc call*(call_773333: Call_ListVirtualServices_773319; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualServices
  ## Returns a list of existing virtual services in a service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual services in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  var path_773334 = newJObject()
  var query_773335 = newJObject()
  add(path_773334, "meshName", newJString(meshName))
  add(query_773335, "nextToken", newJString(nextToken))
  add(query_773335, "limit", newJInt(limit))
  result = call_773333.call(path_773334, query_773335, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_773319(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_773320, base: "/",
    url: url_ListVirtualServices_773321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_773366 = ref object of OpenApiRestCall_772597
proc url_UpdateMesh_773368(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateMesh_773367(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773369 = path.getOrDefault("meshName")
  valid_773369 = validateParameter(valid_773369, JString, required = true,
                                 default = nil)
  if valid_773369 != nil:
    section.add "meshName", valid_773369
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Content-Sha256", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Algorithm")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Algorithm", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Signature")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Signature", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-SignedHeaders", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Credential")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Credential", valid_773376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773378: Call_UpdateMesh_773366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_773378.validator(path, query, header, formData, body)
  let scheme = call_773378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773378.url(scheme.get, call_773378.host, call_773378.base,
                         call_773378.route, valid.getOrDefault("path"))
  result = hook(call_773378, url, valid)

proc call*(call_773379: Call_UpdateMesh_773366; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_773380 = newJObject()
  var body_773381 = newJObject()
  add(path_773380, "meshName", newJString(meshName))
  if body != nil:
    body_773381 = body
  result = call_773379.call(path_773380, nil, nil, nil, body_773381)

var updateMesh* = Call_UpdateMesh_773366(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_773367,
                                      base: "/", url: url_UpdateMesh_773368,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_773352 = ref object of OpenApiRestCall_772597
proc url_DescribeMesh_773354(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeMesh_773353(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773355 = path.getOrDefault("meshName")
  valid_773355 = validateParameter(valid_773355, JString, required = true,
                                 default = nil)
  if valid_773355 != nil:
    section.add "meshName", valid_773355
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
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773363: Call_DescribeMesh_773352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_773363.validator(path, query, header, formData, body)
  let scheme = call_773363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773363.url(scheme.get, call_773363.host, call_773363.base,
                         call_773363.route, valid.getOrDefault("path"))
  result = hook(call_773363, url, valid)

proc call*(call_773364: Call_DescribeMesh_773352; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_773365 = newJObject()
  add(path_773365, "meshName", newJString(meshName))
  result = call_773364.call(path_773365, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_773352(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_773353,
    base: "/", url: url_DescribeMesh_773354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_773382 = ref object of OpenApiRestCall_772597
proc url_DeleteMesh_773384(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMesh_773383(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773385 = path.getOrDefault("meshName")
  valid_773385 = validateParameter(valid_773385, JString, required = true,
                                 default = nil)
  if valid_773385 != nil:
    section.add "meshName", valid_773385
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
  var valid_773386 = header.getOrDefault("X-Amz-Date")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Date", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Security-Token")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Security-Token", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773393: Call_DeleteMesh_773382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_773393.validator(path, query, header, formData, body)
  let scheme = call_773393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773393.url(scheme.get, call_773393.host, call_773393.base,
                         call_773393.route, valid.getOrDefault("path"))
  result = hook(call_773393, url, valid)

proc call*(call_773394: Call_DeleteMesh_773382; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_773395 = newJObject()
  add(path_773395, "meshName", newJString(meshName))
  result = call_773394.call(path_773395, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_773382(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_773383,
                                      base: "/", url: url_DeleteMesh_773384,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_773412 = ref object of OpenApiRestCall_772597
proc url_UpdateRoute_773414(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRoute_773413(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773415 = path.getOrDefault("virtualRouterName")
  valid_773415 = validateParameter(valid_773415, JString, required = true,
                                 default = nil)
  if valid_773415 != nil:
    section.add "virtualRouterName", valid_773415
  var valid_773416 = path.getOrDefault("meshName")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = nil)
  if valid_773416 != nil:
    section.add "meshName", valid_773416
  var valid_773417 = path.getOrDefault("routeName")
  valid_773417 = validateParameter(valid_773417, JString, required = true,
                                 default = nil)
  if valid_773417 != nil:
    section.add "routeName", valid_773417
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
  var valid_773418 = header.getOrDefault("X-Amz-Date")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Date", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Security-Token")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Security-Token", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Content-Sha256", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Algorithm")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Algorithm", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Signature")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Signature", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-SignedHeaders", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Credential")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Credential", valid_773424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773426: Call_UpdateRoute_773412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_773426.validator(path, query, header, formData, body)
  let scheme = call_773426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773426.url(scheme.get, call_773426.host, call_773426.base,
                         call_773426.route, valid.getOrDefault("path"))
  result = hook(call_773426, url, valid)

proc call*(call_773427: Call_UpdateRoute_773412; virtualRouterName: string;
          meshName: string; routeName: string; body: JsonNode): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   body: JObject (required)
  var path_773428 = newJObject()
  var body_773429 = newJObject()
  add(path_773428, "virtualRouterName", newJString(virtualRouterName))
  add(path_773428, "meshName", newJString(meshName))
  add(path_773428, "routeName", newJString(routeName))
  if body != nil:
    body_773429 = body
  result = call_773427.call(path_773428, nil, nil, nil, body_773429)

var updateRoute* = Call_UpdateRoute_773412(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_773413,
                                        base: "/", url: url_UpdateRoute_773414,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_773396 = ref object of OpenApiRestCall_772597
proc url_DescribeRoute_773398(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeRoute_773397(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773399 = path.getOrDefault("virtualRouterName")
  valid_773399 = validateParameter(valid_773399, JString, required = true,
                                 default = nil)
  if valid_773399 != nil:
    section.add "virtualRouterName", valid_773399
  var valid_773400 = path.getOrDefault("meshName")
  valid_773400 = validateParameter(valid_773400, JString, required = true,
                                 default = nil)
  if valid_773400 != nil:
    section.add "meshName", valid_773400
  var valid_773401 = path.getOrDefault("routeName")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = nil)
  if valid_773401 != nil:
    section.add "routeName", valid_773401
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

proc call*(call_773409: Call_DescribeRoute_773396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_DescribeRoute_773396; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  var path_773411 = newJObject()
  add(path_773411, "virtualRouterName", newJString(virtualRouterName))
  add(path_773411, "meshName", newJString(meshName))
  add(path_773411, "routeName", newJString(routeName))
  result = call_773410.call(path_773411, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_773396(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_773397, base: "/", url: url_DescribeRoute_773398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_773430 = ref object of OpenApiRestCall_772597
proc url_DeleteRoute_773432(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteRoute_773431(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete the route in.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the route in.
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773433 = path.getOrDefault("virtualRouterName")
  valid_773433 = validateParameter(valid_773433, JString, required = true,
                                 default = nil)
  if valid_773433 != nil:
    section.add "virtualRouterName", valid_773433
  var valid_773434 = path.getOrDefault("meshName")
  valid_773434 = validateParameter(valid_773434, JString, required = true,
                                 default = nil)
  if valid_773434 != nil:
    section.add "meshName", valid_773434
  var valid_773435 = path.getOrDefault("routeName")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "routeName", valid_773435
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
  var valid_773436 = header.getOrDefault("X-Amz-Date")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Date", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Security-Token")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Security-Token", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Content-Sha256", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Algorithm")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Algorithm", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Signature")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Signature", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-SignedHeaders", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Credential")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Credential", valid_773442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773443: Call_DeleteRoute_773430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_773443.validator(path, query, header, formData, body)
  let scheme = call_773443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773443.url(scheme.get, call_773443.host, call_773443.base,
                         call_773443.route, valid.getOrDefault("path"))
  result = hook(call_773443, url, valid)

proc call*(call_773444: Call_DeleteRoute_773430; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  var path_773445 = newJObject()
  add(path_773445, "virtualRouterName", newJString(virtualRouterName))
  add(path_773445, "meshName", newJString(meshName))
  add(path_773445, "routeName", newJString(routeName))
  result = call_773444.call(path_773445, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_773430(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_773431,
                                        base: "/", url: url_DeleteRoute_773432,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_773461 = ref object of OpenApiRestCall_772597
proc url_UpdateVirtualNode_773463(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVirtualNode_773462(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773464 = path.getOrDefault("meshName")
  valid_773464 = validateParameter(valid_773464, JString, required = true,
                                 default = nil)
  if valid_773464 != nil:
    section.add "meshName", valid_773464
  var valid_773465 = path.getOrDefault("virtualNodeName")
  valid_773465 = validateParameter(valid_773465, JString, required = true,
                                 default = nil)
  if valid_773465 != nil:
    section.add "virtualNodeName", valid_773465
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
  var valid_773466 = header.getOrDefault("X-Amz-Date")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Date", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Security-Token")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Security-Token", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Content-Sha256", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Algorithm")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Algorithm", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Signature")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Signature", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-SignedHeaders", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Credential")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Credential", valid_773472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773474: Call_UpdateVirtualNode_773461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_773474.validator(path, query, header, formData, body)
  let scheme = call_773474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773474.url(scheme.get, call_773474.host, call_773474.base,
                         call_773474.route, valid.getOrDefault("path"))
  result = hook(call_773474, url, valid)

proc call*(call_773475: Call_UpdateVirtualNode_773461; meshName: string;
          virtualNodeName: string; body: JsonNode): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  ##   body: JObject (required)
  var path_773476 = newJObject()
  var body_773477 = newJObject()
  add(path_773476, "meshName", newJString(meshName))
  add(path_773476, "virtualNodeName", newJString(virtualNodeName))
  if body != nil:
    body_773477 = body
  result = call_773475.call(path_773476, nil, nil, nil, body_773477)

var updateVirtualNode* = Call_UpdateVirtualNode_773461(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_773462, base: "/",
    url: url_UpdateVirtualNode_773463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_773446 = ref object of OpenApiRestCall_772597
proc url_DescribeVirtualNode_773448(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeVirtualNode_773447(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773449 = path.getOrDefault("meshName")
  valid_773449 = validateParameter(valid_773449, JString, required = true,
                                 default = nil)
  if valid_773449 != nil:
    section.add "meshName", valid_773449
  var valid_773450 = path.getOrDefault("virtualNodeName")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "virtualNodeName", valid_773450
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
  var valid_773451 = header.getOrDefault("X-Amz-Date")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Date", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Security-Token")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Security-Token", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Content-Sha256", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Algorithm")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Algorithm", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Signature")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Signature", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-SignedHeaders", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Credential")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Credential", valid_773457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773458: Call_DescribeVirtualNode_773446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_773458.validator(path, query, header, formData, body)
  let scheme = call_773458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773458.url(scheme.get, call_773458.host, call_773458.base,
                         call_773458.route, valid.getOrDefault("path"))
  result = hook(call_773458, url, valid)

proc call*(call_773459: Call_DescribeVirtualNode_773446; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_773460 = newJObject()
  add(path_773460, "meshName", newJString(meshName))
  add(path_773460, "virtualNodeName", newJString(virtualNodeName))
  result = call_773459.call(path_773460, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_773446(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_773447, base: "/",
    url: url_DescribeVirtualNode_773448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_773478 = ref object of OpenApiRestCall_772597
proc url_DeleteVirtualNode_773480(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVirtualNode_773479(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773481 = path.getOrDefault("meshName")
  valid_773481 = validateParameter(valid_773481, JString, required = true,
                                 default = nil)
  if valid_773481 != nil:
    section.add "meshName", valid_773481
  var valid_773482 = path.getOrDefault("virtualNodeName")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = nil)
  if valid_773482 != nil:
    section.add "virtualNodeName", valid_773482
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
  var valid_773483 = header.getOrDefault("X-Amz-Date")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Date", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Security-Token")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Security-Token", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Content-Sha256", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Algorithm")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Algorithm", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Signature")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Signature", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-SignedHeaders", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Credential")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Credential", valid_773489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773490: Call_DeleteVirtualNode_773478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_773490.validator(path, query, header, formData, body)
  let scheme = call_773490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773490.url(scheme.get, call_773490.host, call_773490.base,
                         call_773490.route, valid.getOrDefault("path"))
  result = hook(call_773490, url, valid)

proc call*(call_773491: Call_DeleteVirtualNode_773478; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_773492 = newJObject()
  add(path_773492, "meshName", newJString(meshName))
  add(path_773492, "virtualNodeName", newJString(virtualNodeName))
  result = call_773491.call(path_773492, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_773478(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_773479, base: "/",
    url: url_DeleteVirtualNode_773480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_773508 = ref object of OpenApiRestCall_772597
proc url_UpdateVirtualRouter_773510(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVirtualRouter_773509(path: JsonNode; query: JsonNode;
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
  ##           : The name of the service mesh that the virtual router resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773511 = path.getOrDefault("virtualRouterName")
  valid_773511 = validateParameter(valid_773511, JString, required = true,
                                 default = nil)
  if valid_773511 != nil:
    section.add "virtualRouterName", valid_773511
  var valid_773512 = path.getOrDefault("meshName")
  valid_773512 = validateParameter(valid_773512, JString, required = true,
                                 default = nil)
  if valid_773512 != nil:
    section.add "meshName", valid_773512
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
  var valid_773513 = header.getOrDefault("X-Amz-Date")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Date", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Security-Token")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Security-Token", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Content-Sha256", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Algorithm")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Algorithm", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Signature")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Signature", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-SignedHeaders", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Credential")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Credential", valid_773519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773521: Call_UpdateVirtualRouter_773508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_773521.validator(path, query, header, formData, body)
  let scheme = call_773521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773521.url(scheme.get, call_773521.host, call_773521.base,
                         call_773521.route, valid.getOrDefault("path"))
  result = hook(call_773521, url, valid)

proc call*(call_773522: Call_UpdateVirtualRouter_773508; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  var path_773523 = newJObject()
  var body_773524 = newJObject()
  add(path_773523, "virtualRouterName", newJString(virtualRouterName))
  add(path_773523, "meshName", newJString(meshName))
  if body != nil:
    body_773524 = body
  result = call_773522.call(path_773523, nil, nil, nil, body_773524)

var updateVirtualRouter* = Call_UpdateVirtualRouter_773508(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_773509, base: "/",
    url: url_UpdateVirtualRouter_773510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_773493 = ref object of OpenApiRestCall_772597
proc url_DescribeVirtualRouter_773495(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeVirtualRouter_773494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773496 = path.getOrDefault("virtualRouterName")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = nil)
  if valid_773496 != nil:
    section.add "virtualRouterName", valid_773496
  var valid_773497 = path.getOrDefault("meshName")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = nil)
  if valid_773497 != nil:
    section.add "meshName", valid_773497
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
  var valid_773498 = header.getOrDefault("X-Amz-Date")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Date", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Security-Token")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Security-Token", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773505: Call_DescribeVirtualRouter_773493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_773505.validator(path, query, header, formData, body)
  let scheme = call_773505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773505.url(scheme.get, call_773505.host, call_773505.base,
                         call_773505.route, valid.getOrDefault("path"))
  result = hook(call_773505, url, valid)

proc call*(call_773506: Call_DescribeVirtualRouter_773493;
          virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  var path_773507 = newJObject()
  add(path_773507, "virtualRouterName", newJString(virtualRouterName))
  add(path_773507, "meshName", newJString(meshName))
  result = call_773506.call(path_773507, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_773493(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_773494, base: "/",
    url: url_DescribeVirtualRouter_773495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_773525 = ref object of OpenApiRestCall_772597
proc url_DeleteVirtualRouter_773527(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVirtualRouter_773526(path: JsonNode; query: JsonNode;
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
  ##           : The name of the service mesh to delete the virtual router in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_773528 = path.getOrDefault("virtualRouterName")
  valid_773528 = validateParameter(valid_773528, JString, required = true,
                                 default = nil)
  if valid_773528 != nil:
    section.add "virtualRouterName", valid_773528
  var valid_773529 = path.getOrDefault("meshName")
  valid_773529 = validateParameter(valid_773529, JString, required = true,
                                 default = nil)
  if valid_773529 != nil:
    section.add "meshName", valid_773529
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
  var valid_773530 = header.getOrDefault("X-Amz-Date")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Date", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Security-Token")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Security-Token", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Content-Sha256", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Algorithm")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Algorithm", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Signature")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Signature", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-SignedHeaders", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Credential")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Credential", valid_773536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773537: Call_DeleteVirtualRouter_773525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_773537.validator(path, query, header, formData, body)
  let scheme = call_773537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773537.url(scheme.get, call_773537.host, call_773537.base,
                         call_773537.route, valid.getOrDefault("path"))
  result = hook(call_773537, url, valid)

proc call*(call_773538: Call_DeleteVirtualRouter_773525; virtualRouterName: string;
          meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  var path_773539 = newJObject()
  add(path_773539, "virtualRouterName", newJString(virtualRouterName))
  add(path_773539, "meshName", newJString(meshName))
  result = call_773538.call(path_773539, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_773525(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_773526, base: "/",
    url: url_DeleteVirtualRouter_773527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_773555 = ref object of OpenApiRestCall_772597
proc url_UpdateVirtualService_773557(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVirtualService_773556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773558 = path.getOrDefault("meshName")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = nil)
  if valid_773558 != nil:
    section.add "meshName", valid_773558
  var valid_773559 = path.getOrDefault("virtualServiceName")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "virtualServiceName", valid_773559
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
  var valid_773560 = header.getOrDefault("X-Amz-Date")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Date", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Security-Token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Security-Token", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Content-Sha256", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Algorithm")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Algorithm", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Signature")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Signature", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-SignedHeaders", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Credential")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Credential", valid_773566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_UpdateVirtualService_773555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_UpdateVirtualService_773555; meshName: string;
          body: JsonNode; virtualServiceName: string): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  var path_773570 = newJObject()
  var body_773571 = newJObject()
  add(path_773570, "meshName", newJString(meshName))
  if body != nil:
    body_773571 = body
  add(path_773570, "virtualServiceName", newJString(virtualServiceName))
  result = call_773569.call(path_773570, nil, nil, nil, body_773571)

var updateVirtualService* = Call_UpdateVirtualService_773555(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_773556, base: "/",
    url: url_UpdateVirtualService_773557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_773540 = ref object of OpenApiRestCall_772597
proc url_DescribeVirtualService_773542(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeVirtualService_773541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773543 = path.getOrDefault("meshName")
  valid_773543 = validateParameter(valid_773543, JString, required = true,
                                 default = nil)
  if valid_773543 != nil:
    section.add "meshName", valid_773543
  var valid_773544 = path.getOrDefault("virtualServiceName")
  valid_773544 = validateParameter(valid_773544, JString, required = true,
                                 default = nil)
  if valid_773544 != nil:
    section.add "virtualServiceName", valid_773544
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
  var valid_773545 = header.getOrDefault("X-Amz-Date")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Date", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Security-Token")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Security-Token", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Content-Sha256", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Algorithm")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Algorithm", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Signature")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Signature", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-SignedHeaders", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Credential")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Credential", valid_773551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773552: Call_DescribeVirtualService_773540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_773552.validator(path, query, header, formData, body)
  let scheme = call_773552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773552.url(scheme.get, call_773552.host, call_773552.base,
                         call_773552.route, valid.getOrDefault("path"))
  result = hook(call_773552, url, valid)

proc call*(call_773553: Call_DescribeVirtualService_773540; meshName: string;
          virtualServiceName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  var path_773554 = newJObject()
  add(path_773554, "meshName", newJString(meshName))
  add(path_773554, "virtualServiceName", newJString(virtualServiceName))
  result = call_773553.call(path_773554, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_773540(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_773541, base: "/",
    url: url_DescribeVirtualService_773542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_773572 = ref object of OpenApiRestCall_772597
proc url_DeleteVirtualService_773574(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVirtualService_773573(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual service in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_773575 = path.getOrDefault("meshName")
  valid_773575 = validateParameter(valid_773575, JString, required = true,
                                 default = nil)
  if valid_773575 != nil:
    section.add "meshName", valid_773575
  var valid_773576 = path.getOrDefault("virtualServiceName")
  valid_773576 = validateParameter(valid_773576, JString, required = true,
                                 default = nil)
  if valid_773576 != nil:
    section.add "virtualServiceName", valid_773576
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
  var valid_773577 = header.getOrDefault("X-Amz-Date")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Date", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Security-Token")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Security-Token", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Content-Sha256", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Algorithm")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Algorithm", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Signature")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Signature", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-SignedHeaders", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Credential")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Credential", valid_773583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773584: Call_DeleteVirtualService_773572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_773584.validator(path, query, header, formData, body)
  let scheme = call_773584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773584.url(scheme.get, call_773584.host, call_773584.base,
                         call_773584.route, valid.getOrDefault("path"))
  result = hook(call_773584, url, valid)

proc call*(call_773585: Call_DeleteVirtualService_773572; meshName: string;
          virtualServiceName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  var path_773586 = newJObject()
  add(path_773586, "meshName", newJString(meshName))
  add(path_773586, "virtualServiceName", newJString(virtualServiceName))
  result = call_773585.call(path_773586, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_773572(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_773573, base: "/",
    url: url_DeleteVirtualService_773574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773587 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773589(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773588(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an App Mesh resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_773590 = query.getOrDefault("resourceArn")
  valid_773590 = validateParameter(valid_773590, JString, required = true,
                                 default = nil)
  if valid_773590 != nil:
    section.add "resourceArn", valid_773590
  var valid_773591 = query.getOrDefault("nextToken")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "nextToken", valid_773591
  var valid_773592 = query.getOrDefault("limit")
  valid_773592 = validateParameter(valid_773592, JInt, required = false, default = nil)
  if valid_773592 != nil:
    section.add "limit", valid_773592
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
  var valid_773593 = header.getOrDefault("X-Amz-Date")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Date", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Security-Token")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Security-Token", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Signature")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Signature", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-SignedHeaders", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Credential")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Credential", valid_773599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773600: Call_ListTagsForResource_773587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_773600.validator(path, query, header, formData, body)
  let scheme = call_773600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773600.url(scheme.get, call_773600.host, call_773600.base,
                         call_773600.route, valid.getOrDefault("path"))
  result = hook(call_773600, url, valid)

proc call*(call_773601: Call_ListTagsForResource_773587; resourceArn: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listTagsForResource
  ## List the tags for an App Mesh resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  var query_773602 = newJObject()
  add(query_773602, "resourceArn", newJString(resourceArn))
  add(query_773602, "nextToken", newJString(nextToken))
  add(query_773602, "limit", newJInt(limit))
  result = call_773601.call(nil, query_773602, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773587(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_773588, base: "/",
    url: url_ListTagsForResource_773589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773603 = ref object of OpenApiRestCall_772597
proc url_TagResource_773605(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773604(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_773606 = query.getOrDefault("resourceArn")
  valid_773606 = validateParameter(valid_773606, JString, required = true,
                                 default = nil)
  if valid_773606 != nil:
    section.add "resourceArn", valid_773606
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
  var valid_773607 = header.getOrDefault("X-Amz-Date")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Date", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Security-Token")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Security-Token", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Content-Sha256", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Algorithm")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Algorithm", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Signature")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Signature", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-SignedHeaders", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Credential")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Credential", valid_773613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773615: Call_TagResource_773603; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_773615.validator(path, query, header, formData, body)
  let scheme = call_773615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773615.url(scheme.get, call_773615.host, call_773615.base,
                         call_773615.route, valid.getOrDefault("path"))
  result = hook(call_773615, url, valid)

proc call*(call_773616: Call_TagResource_773603; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  ##   body: JObject (required)
  var query_773617 = newJObject()
  var body_773618 = newJObject()
  add(query_773617, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_773618 = body
  result = call_773616.call(nil, query_773617, nil, nil, body_773618)

var tagResource* = Call_TagResource_773603(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_773604,
                                        base: "/", url: url_TagResource_773605,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773619 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773621(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773620(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_773622 = query.getOrDefault("resourceArn")
  valid_773622 = validateParameter(valid_773622, JString, required = true,
                                 default = nil)
  if valid_773622 != nil:
    section.add "resourceArn", valid_773622
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
  var valid_773623 = header.getOrDefault("X-Amz-Date")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Date", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Security-Token")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Security-Token", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Content-Sha256", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Algorithm")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Algorithm", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Signature")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Signature", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-SignedHeaders", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Credential")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Credential", valid_773629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773631: Call_UntagResource_773619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_773631.validator(path, query, header, formData, body)
  let scheme = call_773631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773631.url(scheme.get, call_773631.host, call_773631.base,
                         call_773631.route, valid.getOrDefault("path"))
  result = hook(call_773631, url, valid)

proc call*(call_773632: Call_UntagResource_773619; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  ##   body: JObject (required)
  var query_773633 = newJObject()
  var body_773634 = newJObject()
  add(query_773633, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_773634 = body
  result = call_773632.call(nil, query_773633, nil, nil, body_773634)

var untagResource* = Call_UntagResource_773619(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_773620,
    base: "/", url: url_UntagResource_773621, schemes: {Scheme.Https, Scheme.Http})
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

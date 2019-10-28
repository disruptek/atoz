
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_590960 = ref object of OpenApiRestCall_590364
proc url_CreateMesh_590962(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMesh_590961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590963 = header.getOrDefault("X-Amz-Signature")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Signature", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Content-Sha256", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Date")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Date", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Credential")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Credential", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-Security-Token")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-Security-Token", valid_590967
  var valid_590968 = header.getOrDefault("X-Amz-Algorithm")
  valid_590968 = validateParameter(valid_590968, JString, required = false,
                                 default = nil)
  if valid_590968 != nil:
    section.add "X-Amz-Algorithm", valid_590968
  var valid_590969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590969 = validateParameter(valid_590969, JString, required = false,
                                 default = nil)
  if valid_590969 != nil:
    section.add "X-Amz-SignedHeaders", valid_590969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590971: Call_CreateMesh_590960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  let valid = call_590971.validator(path, query, header, formData, body)
  let scheme = call_590971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590971.url(scheme.get, call_590971.host, call_590971.base,
                         call_590971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590971, url, valid)

proc call*(call_590972: Call_CreateMesh_590960; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_590973 = newJObject()
  if body != nil:
    body_590973 = body
  result = call_590972.call(nil, nil, nil, nil, body_590973)

var createMesh* = Call_CreateMesh_590960(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_CreateMesh_590961,
                                      base: "/", url: url_CreateMesh_590962,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_590703 = ref object of OpenApiRestCall_590364
proc url_ListMeshes_590705(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListMeshes_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590817 = query.getOrDefault("nextToken")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "nextToken", valid_590817
  var valid_590818 = query.getOrDefault("limit")
  valid_590818 = validateParameter(valid_590818, JInt, required = false, default = nil)
  if valid_590818 != nil:
    section.add "limit", valid_590818
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
  var valid_590819 = header.getOrDefault("X-Amz-Signature")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Signature", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Content-Sha256", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Date")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Date", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Credential")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Credential", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-Security-Token")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-Security-Token", valid_590823
  var valid_590824 = header.getOrDefault("X-Amz-Algorithm")
  valid_590824 = validateParameter(valid_590824, JString, required = false,
                                 default = nil)
  if valid_590824 != nil:
    section.add "X-Amz-Algorithm", valid_590824
  var valid_590825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590825 = validateParameter(valid_590825, JString, required = false,
                                 default = nil)
  if valid_590825 != nil:
    section.add "X-Amz-SignedHeaders", valid_590825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590848: Call_ListMeshes_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_590848.validator(path, query, header, formData, body)
  let scheme = call_590848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590848.url(scheme.get, call_590848.host, call_590848.base,
                         call_590848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590848, url, valid)

proc call*(call_590919: Call_ListMeshes_590703; nextToken: string = ""; limit: int = 0): Recallable =
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
  var query_590920 = newJObject()
  add(query_590920, "nextToken", newJString(nextToken))
  add(query_590920, "limit", newJInt(limit))
  result = call_590919.call(nil, query_590920, nil, nil, nil)

var listMeshes* = Call_ListMeshes_590703(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_ListMeshes_590704,
                                      base: "/", url: url_ListMeshes_590705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_591006 = ref object of OpenApiRestCall_590364
proc url_CreateRoute_591008(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_CreateRoute_591007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_591009 = path.getOrDefault("meshName")
  valid_591009 = validateParameter(valid_591009, JString, required = true,
                                 default = nil)
  if valid_591009 != nil:
    section.add "meshName", valid_591009
  var valid_591010 = path.getOrDefault("virtualRouterName")
  valid_591010 = validateParameter(valid_591010, JString, required = true,
                                 default = nil)
  if valid_591010 != nil:
    section.add "virtualRouterName", valid_591010
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
  var valid_591011 = header.getOrDefault("X-Amz-Signature")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Signature", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-Content-Sha256", valid_591012
  var valid_591013 = header.getOrDefault("X-Amz-Date")
  valid_591013 = validateParameter(valid_591013, JString, required = false,
                                 default = nil)
  if valid_591013 != nil:
    section.add "X-Amz-Date", valid_591013
  var valid_591014 = header.getOrDefault("X-Amz-Credential")
  valid_591014 = validateParameter(valid_591014, JString, required = false,
                                 default = nil)
  if valid_591014 != nil:
    section.add "X-Amz-Credential", valid_591014
  var valid_591015 = header.getOrDefault("X-Amz-Security-Token")
  valid_591015 = validateParameter(valid_591015, JString, required = false,
                                 default = nil)
  if valid_591015 != nil:
    section.add "X-Amz-Security-Token", valid_591015
  var valid_591016 = header.getOrDefault("X-Amz-Algorithm")
  valid_591016 = validateParameter(valid_591016, JString, required = false,
                                 default = nil)
  if valid_591016 != nil:
    section.add "X-Amz-Algorithm", valid_591016
  var valid_591017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-SignedHeaders", valid_591017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591019: Call_CreateRoute_591006; path: JsonNode; query: JsonNode;
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
  let valid = call_591019.validator(path, query, header, formData, body)
  let scheme = call_591019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591019.url(scheme.get, call_591019.host, call_591019.base,
                         call_591019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591019, url, valid)

proc call*(call_591020: Call_CreateRoute_591006; meshName: string; body: JsonNode;
          virtualRouterName: string): Recallable =
  ## createRoute
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the route in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  var path_591021 = newJObject()
  var body_591022 = newJObject()
  add(path_591021, "meshName", newJString(meshName))
  if body != nil:
    body_591022 = body
  add(path_591021, "virtualRouterName", newJString(virtualRouterName))
  result = call_591020.call(path_591021, nil, nil, nil, body_591022)

var createRoute* = Call_CreateRoute_591006(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_591007,
                                        base: "/", url: url_CreateRoute_591008,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_590974 = ref object of OpenApiRestCall_590364
proc url_ListRoutes_590976(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_ListRoutes_590975(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to list routes in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_590991 = path.getOrDefault("meshName")
  valid_590991 = validateParameter(valid_590991, JString, required = true,
                                 default = nil)
  if valid_590991 != nil:
    section.add "meshName", valid_590991
  var valid_590992 = path.getOrDefault("virtualRouterName")
  valid_590992 = validateParameter(valid_590992, JString, required = true,
                                 default = nil)
  if valid_590992 != nil:
    section.add "virtualRouterName", valid_590992
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
  var valid_590993 = query.getOrDefault("nextToken")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "nextToken", valid_590993
  var valid_590994 = query.getOrDefault("limit")
  valid_590994 = validateParameter(valid_590994, JInt, required = false, default = nil)
  if valid_590994 != nil:
    section.add "limit", valid_590994
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
  var valid_590995 = header.getOrDefault("X-Amz-Signature")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Signature", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Content-Sha256", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Date")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Date", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Credential")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Credential", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-Security-Token")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-Security-Token", valid_590999
  var valid_591000 = header.getOrDefault("X-Amz-Algorithm")
  valid_591000 = validateParameter(valid_591000, JString, required = false,
                                 default = nil)
  if valid_591000 != nil:
    section.add "X-Amz-Algorithm", valid_591000
  var valid_591001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591001 = validateParameter(valid_591001, JString, required = false,
                                 default = nil)
  if valid_591001 != nil:
    section.add "X-Amz-SignedHeaders", valid_591001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591002: Call_ListRoutes_590974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_591002.validator(path, query, header, formData, body)
  let scheme = call_591002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591002.url(scheme.get, call_591002.host, call_591002.base,
                         call_591002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591002, url, valid)

proc call*(call_591003: Call_ListRoutes_590974; meshName: string;
          virtualRouterName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to list routes in.
  var path_591004 = newJObject()
  var query_591005 = newJObject()
  add(query_591005, "nextToken", newJString(nextToken))
  add(query_591005, "limit", newJInt(limit))
  add(path_591004, "meshName", newJString(meshName))
  add(path_591004, "virtualRouterName", newJString(virtualRouterName))
  result = call_591003.call(path_591004, query_591005, nil, nil, nil)

var listRoutes* = Call_ListRoutes_590974(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_590975,
                                      base: "/", url: url_ListRoutes_590976,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_591040 = ref object of OpenApiRestCall_590364
proc url_CreateVirtualNode_591042(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualNode_591041(path: JsonNode; query: JsonNode;
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
  var valid_591043 = path.getOrDefault("meshName")
  valid_591043 = validateParameter(valid_591043, JString, required = true,
                                 default = nil)
  if valid_591043 != nil:
    section.add "meshName", valid_591043
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
  var valid_591044 = header.getOrDefault("X-Amz-Signature")
  valid_591044 = validateParameter(valid_591044, JString, required = false,
                                 default = nil)
  if valid_591044 != nil:
    section.add "X-Amz-Signature", valid_591044
  var valid_591045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-Content-Sha256", valid_591045
  var valid_591046 = header.getOrDefault("X-Amz-Date")
  valid_591046 = validateParameter(valid_591046, JString, required = false,
                                 default = nil)
  if valid_591046 != nil:
    section.add "X-Amz-Date", valid_591046
  var valid_591047 = header.getOrDefault("X-Amz-Credential")
  valid_591047 = validateParameter(valid_591047, JString, required = false,
                                 default = nil)
  if valid_591047 != nil:
    section.add "X-Amz-Credential", valid_591047
  var valid_591048 = header.getOrDefault("X-Amz-Security-Token")
  valid_591048 = validateParameter(valid_591048, JString, required = false,
                                 default = nil)
  if valid_591048 != nil:
    section.add "X-Amz-Security-Token", valid_591048
  var valid_591049 = header.getOrDefault("X-Amz-Algorithm")
  valid_591049 = validateParameter(valid_591049, JString, required = false,
                                 default = nil)
  if valid_591049 != nil:
    section.add "X-Amz-Algorithm", valid_591049
  var valid_591050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "X-Amz-SignedHeaders", valid_591050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591052: Call_CreateVirtualNode_591040; path: JsonNode;
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
  let valid = call_591052.validator(path, query, header, formData, body)
  let scheme = call_591052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591052.url(scheme.get, call_591052.host, call_591052.base,
                         call_591052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591052, url, valid)

proc call*(call_591053: Call_CreateVirtualNode_591040; meshName: string;
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
  var path_591054 = newJObject()
  var body_591055 = newJObject()
  add(path_591054, "meshName", newJString(meshName))
  if body != nil:
    body_591055 = body
  result = call_591053.call(path_591054, nil, nil, nil, body_591055)

var createVirtualNode* = Call_CreateVirtualNode_591040(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_591041, base: "/",
    url: url_CreateVirtualNode_591042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_591023 = ref object of OpenApiRestCall_590364
proc url_ListVirtualNodes_591025(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualNodes_591024(path: JsonNode; query: JsonNode;
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
  var valid_591026 = path.getOrDefault("meshName")
  valid_591026 = validateParameter(valid_591026, JString, required = true,
                                 default = nil)
  if valid_591026 != nil:
    section.add "meshName", valid_591026
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
  var valid_591027 = query.getOrDefault("nextToken")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "nextToken", valid_591027
  var valid_591028 = query.getOrDefault("limit")
  valid_591028 = validateParameter(valid_591028, JInt, required = false, default = nil)
  if valid_591028 != nil:
    section.add "limit", valid_591028
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
  var valid_591029 = header.getOrDefault("X-Amz-Signature")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-Signature", valid_591029
  var valid_591030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591030 = validateParameter(valid_591030, JString, required = false,
                                 default = nil)
  if valid_591030 != nil:
    section.add "X-Amz-Content-Sha256", valid_591030
  var valid_591031 = header.getOrDefault("X-Amz-Date")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "X-Amz-Date", valid_591031
  var valid_591032 = header.getOrDefault("X-Amz-Credential")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "X-Amz-Credential", valid_591032
  var valid_591033 = header.getOrDefault("X-Amz-Security-Token")
  valid_591033 = validateParameter(valid_591033, JString, required = false,
                                 default = nil)
  if valid_591033 != nil:
    section.add "X-Amz-Security-Token", valid_591033
  var valid_591034 = header.getOrDefault("X-Amz-Algorithm")
  valid_591034 = validateParameter(valid_591034, JString, required = false,
                                 default = nil)
  if valid_591034 != nil:
    section.add "X-Amz-Algorithm", valid_591034
  var valid_591035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-SignedHeaders", valid_591035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591036: Call_ListVirtualNodes_591023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_591036.validator(path, query, header, formData, body)
  let scheme = call_591036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591036.url(scheme.get, call_591036.host, call_591036.base,
                         call_591036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591036, url, valid)

proc call*(call_591037: Call_ListVirtualNodes_591023; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual nodes in.
  var path_591038 = newJObject()
  var query_591039 = newJObject()
  add(query_591039, "nextToken", newJString(nextToken))
  add(query_591039, "limit", newJInt(limit))
  add(path_591038, "meshName", newJString(meshName))
  result = call_591037.call(path_591038, query_591039, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_591023(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_591024, base: "/",
    url: url_ListVirtualNodes_591025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_591073 = ref object of OpenApiRestCall_590364
proc url_CreateVirtualRouter_591075(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualRouter_591074(path: JsonNode; query: JsonNode;
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
  var valid_591076 = path.getOrDefault("meshName")
  valid_591076 = validateParameter(valid_591076, JString, required = true,
                                 default = nil)
  if valid_591076 != nil:
    section.add "meshName", valid_591076
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
  var valid_591077 = header.getOrDefault("X-Amz-Signature")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-Signature", valid_591077
  var valid_591078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591078 = validateParameter(valid_591078, JString, required = false,
                                 default = nil)
  if valid_591078 != nil:
    section.add "X-Amz-Content-Sha256", valid_591078
  var valid_591079 = header.getOrDefault("X-Amz-Date")
  valid_591079 = validateParameter(valid_591079, JString, required = false,
                                 default = nil)
  if valid_591079 != nil:
    section.add "X-Amz-Date", valid_591079
  var valid_591080 = header.getOrDefault("X-Amz-Credential")
  valid_591080 = validateParameter(valid_591080, JString, required = false,
                                 default = nil)
  if valid_591080 != nil:
    section.add "X-Amz-Credential", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Security-Token")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Security-Token", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Algorithm")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Algorithm", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-SignedHeaders", valid_591083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591085: Call_CreateVirtualRouter_591073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_591085.validator(path, query, header, formData, body)
  let scheme = call_591085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591085.url(scheme.get, call_591085.host, call_591085.base,
                         call_591085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591085, url, valid)

proc call*(call_591086: Call_CreateVirtualRouter_591073; meshName: string;
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
  var path_591087 = newJObject()
  var body_591088 = newJObject()
  add(path_591087, "meshName", newJString(meshName))
  if body != nil:
    body_591088 = body
  result = call_591086.call(path_591087, nil, nil, nil, body_591088)

var createVirtualRouter* = Call_CreateVirtualRouter_591073(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_591074, base: "/",
    url: url_CreateVirtualRouter_591075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_591056 = ref object of OpenApiRestCall_590364
proc url_ListVirtualRouters_591058(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualRouters_591057(path: JsonNode; query: JsonNode;
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
  var valid_591059 = path.getOrDefault("meshName")
  valid_591059 = validateParameter(valid_591059, JString, required = true,
                                 default = nil)
  if valid_591059 != nil:
    section.add "meshName", valid_591059
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
  var valid_591060 = query.getOrDefault("nextToken")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "nextToken", valid_591060
  var valid_591061 = query.getOrDefault("limit")
  valid_591061 = validateParameter(valid_591061, JInt, required = false, default = nil)
  if valid_591061 != nil:
    section.add "limit", valid_591061
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
  var valid_591062 = header.getOrDefault("X-Amz-Signature")
  valid_591062 = validateParameter(valid_591062, JString, required = false,
                                 default = nil)
  if valid_591062 != nil:
    section.add "X-Amz-Signature", valid_591062
  var valid_591063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591063 = validateParameter(valid_591063, JString, required = false,
                                 default = nil)
  if valid_591063 != nil:
    section.add "X-Amz-Content-Sha256", valid_591063
  var valid_591064 = header.getOrDefault("X-Amz-Date")
  valid_591064 = validateParameter(valid_591064, JString, required = false,
                                 default = nil)
  if valid_591064 != nil:
    section.add "X-Amz-Date", valid_591064
  var valid_591065 = header.getOrDefault("X-Amz-Credential")
  valid_591065 = validateParameter(valid_591065, JString, required = false,
                                 default = nil)
  if valid_591065 != nil:
    section.add "X-Amz-Credential", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Security-Token")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Security-Token", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Algorithm")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Algorithm", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-SignedHeaders", valid_591068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591069: Call_ListVirtualRouters_591056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_591069.validator(path, query, header, formData, body)
  let scheme = call_591069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591069.url(scheme.get, call_591069.host, call_591069.base,
                         call_591069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591069, url, valid)

proc call*(call_591070: Call_ListVirtualRouters_591056; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual routers in.
  var path_591071 = newJObject()
  var query_591072 = newJObject()
  add(query_591072, "nextToken", newJString(nextToken))
  add(query_591072, "limit", newJInt(limit))
  add(path_591071, "meshName", newJString(meshName))
  result = call_591070.call(path_591071, query_591072, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_591056(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_591057, base: "/",
    url: url_ListVirtualRouters_591058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_591106 = ref object of OpenApiRestCall_590364
proc url_CreateVirtualService_591108(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualService_591107(path: JsonNode; query: JsonNode;
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
  var valid_591109 = path.getOrDefault("meshName")
  valid_591109 = validateParameter(valid_591109, JString, required = true,
                                 default = nil)
  if valid_591109 != nil:
    section.add "meshName", valid_591109
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
  var valid_591110 = header.getOrDefault("X-Amz-Signature")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Signature", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Content-Sha256", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Date")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Date", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Credential")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Credential", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Security-Token")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Security-Token", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Algorithm")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Algorithm", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-SignedHeaders", valid_591116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591118: Call_CreateVirtualService_591106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_591118.validator(path, query, header, formData, body)
  let scheme = call_591118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591118.url(scheme.get, call_591118.host, call_591118.base,
                         call_591118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591118, url, valid)

proc call*(call_591119: Call_CreateVirtualService_591106; meshName: string;
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
  var path_591120 = newJObject()
  var body_591121 = newJObject()
  add(path_591120, "meshName", newJString(meshName))
  if body != nil:
    body_591121 = body
  result = call_591119.call(path_591120, nil, nil, nil, body_591121)

var createVirtualService* = Call_CreateVirtualService_591106(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_591107, base: "/",
    url: url_CreateVirtualService_591108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_591089 = ref object of OpenApiRestCall_590364
proc url_ListVirtualServices_591091(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualServices_591090(path: JsonNode; query: JsonNode;
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
  var valid_591092 = path.getOrDefault("meshName")
  valid_591092 = validateParameter(valid_591092, JString, required = true,
                                 default = nil)
  if valid_591092 != nil:
    section.add "meshName", valid_591092
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
  var valid_591093 = query.getOrDefault("nextToken")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "nextToken", valid_591093
  var valid_591094 = query.getOrDefault("limit")
  valid_591094 = validateParameter(valid_591094, JInt, required = false, default = nil)
  if valid_591094 != nil:
    section.add "limit", valid_591094
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
  var valid_591095 = header.getOrDefault("X-Amz-Signature")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "X-Amz-Signature", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Content-Sha256", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Date")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Date", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Credential")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Credential", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Security-Token")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Security-Token", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Algorithm")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Algorithm", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-SignedHeaders", valid_591101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591102: Call_ListVirtualServices_591089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_591102.validator(path, query, header, formData, body)
  let scheme = call_591102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591102.url(scheme.get, call_591102.host, call_591102.base,
                         call_591102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591102, url, valid)

proc call*(call_591103: Call_ListVirtualServices_591089; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualServices
  ## Returns a list of existing virtual services in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual services in.
  var path_591104 = newJObject()
  var query_591105 = newJObject()
  add(query_591105, "nextToken", newJString(nextToken))
  add(query_591105, "limit", newJInt(limit))
  add(path_591104, "meshName", newJString(meshName))
  result = call_591103.call(path_591104, query_591105, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_591089(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_591090, base: "/",
    url: url_ListVirtualServices_591091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_591136 = ref object of OpenApiRestCall_590364
proc url_UpdateMesh_591138(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateMesh_591137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591139 = path.getOrDefault("meshName")
  valid_591139 = validateParameter(valid_591139, JString, required = true,
                                 default = nil)
  if valid_591139 != nil:
    section.add "meshName", valid_591139
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
  var valid_591140 = header.getOrDefault("X-Amz-Signature")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Signature", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Content-Sha256", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Date")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Date", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Credential")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Credential", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Security-Token")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Security-Token", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Algorithm")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Algorithm", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-SignedHeaders", valid_591146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591148: Call_UpdateMesh_591136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_591148.validator(path, query, header, formData, body)
  let scheme = call_591148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591148.url(scheme.get, call_591148.host, call_591148.base,
                         call_591148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591148, url, valid)

proc call*(call_591149: Call_UpdateMesh_591136; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_591150 = newJObject()
  var body_591151 = newJObject()
  add(path_591150, "meshName", newJString(meshName))
  if body != nil:
    body_591151 = body
  result = call_591149.call(path_591150, nil, nil, nil, body_591151)

var updateMesh* = Call_UpdateMesh_591136(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_591137,
                                      base: "/", url: url_UpdateMesh_591138,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_591122 = ref object of OpenApiRestCall_590364
proc url_DescribeMesh_591124(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeMesh_591123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591125 = path.getOrDefault("meshName")
  valid_591125 = validateParameter(valid_591125, JString, required = true,
                                 default = nil)
  if valid_591125 != nil:
    section.add "meshName", valid_591125
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
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591133: Call_DescribeMesh_591122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_591133.validator(path, query, header, formData, body)
  let scheme = call_591133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591133.url(scheme.get, call_591133.host, call_591133.base,
                         call_591133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591133, url, valid)

proc call*(call_591134: Call_DescribeMesh_591122; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_591135 = newJObject()
  add(path_591135, "meshName", newJString(meshName))
  result = call_591134.call(path_591135, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_591122(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_591123,
    base: "/", url: url_DescribeMesh_591124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_591152 = ref object of OpenApiRestCall_590364
proc url_DeleteMesh_591154(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteMesh_591153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591155 = path.getOrDefault("meshName")
  valid_591155 = validateParameter(valid_591155, JString, required = true,
                                 default = nil)
  if valid_591155 != nil:
    section.add "meshName", valid_591155
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
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591163: Call_DeleteMesh_591152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_591163.validator(path, query, header, formData, body)
  let scheme = call_591163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591163.url(scheme.get, call_591163.host, call_591163.base,
                         call_591163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591163, url, valid)

proc call*(call_591164: Call_DeleteMesh_591152; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_591165 = newJObject()
  add(path_591165, "meshName", newJString(meshName))
  result = call_591164.call(path_591165, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_591152(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_591153,
                                      base: "/", url: url_DeleteMesh_591154,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_591182 = ref object of OpenApiRestCall_590364
proc url_UpdateRoute_591184(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateRoute_591183(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_591185 = path.getOrDefault("routeName")
  valid_591185 = validateParameter(valid_591185, JString, required = true,
                                 default = nil)
  if valid_591185 != nil:
    section.add "routeName", valid_591185
  var valid_591186 = path.getOrDefault("meshName")
  valid_591186 = validateParameter(valid_591186, JString, required = true,
                                 default = nil)
  if valid_591186 != nil:
    section.add "meshName", valid_591186
  var valid_591187 = path.getOrDefault("virtualRouterName")
  valid_591187 = validateParameter(valid_591187, JString, required = true,
                                 default = nil)
  if valid_591187 != nil:
    section.add "virtualRouterName", valid_591187
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
  var valid_591188 = header.getOrDefault("X-Amz-Signature")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Signature", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Content-Sha256", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Date")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Date", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Credential")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Credential", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-Security-Token")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Security-Token", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-Algorithm")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-Algorithm", valid_591193
  var valid_591194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591194 = validateParameter(valid_591194, JString, required = false,
                                 default = nil)
  if valid_591194 != nil:
    section.add "X-Amz-SignedHeaders", valid_591194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591196: Call_UpdateRoute_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_591196.validator(path, query, header, formData, body)
  let scheme = call_591196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591196.url(scheme.get, call_591196.host, call_591196.base,
                         call_591196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591196, url, valid)

proc call*(call_591197: Call_UpdateRoute_591182; routeName: string; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_591198 = newJObject()
  var body_591199 = newJObject()
  add(path_591198, "routeName", newJString(routeName))
  add(path_591198, "meshName", newJString(meshName))
  if body != nil:
    body_591199 = body
  add(path_591198, "virtualRouterName", newJString(virtualRouterName))
  result = call_591197.call(path_591198, nil, nil, nil, body_591199)

var updateRoute* = Call_UpdateRoute_591182(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_591183,
                                        base: "/", url: url_UpdateRoute_591184,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_591166 = ref object of OpenApiRestCall_590364
proc url_DescribeRoute_591168(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DescribeRoute_591167(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_591169 = path.getOrDefault("routeName")
  valid_591169 = validateParameter(valid_591169, JString, required = true,
                                 default = nil)
  if valid_591169 != nil:
    section.add "routeName", valid_591169
  var valid_591170 = path.getOrDefault("meshName")
  valid_591170 = validateParameter(valid_591170, JString, required = true,
                                 default = nil)
  if valid_591170 != nil:
    section.add "meshName", valid_591170
  var valid_591171 = path.getOrDefault("virtualRouterName")
  valid_591171 = validateParameter(valid_591171, JString, required = true,
                                 default = nil)
  if valid_591171 != nil:
    section.add "virtualRouterName", valid_591171
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
  var valid_591172 = header.getOrDefault("X-Amz-Signature")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Signature", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Content-Sha256", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Date")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Date", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Credential")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Credential", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Security-Token")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Security-Token", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Algorithm")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Algorithm", valid_591177
  var valid_591178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amz-SignedHeaders", valid_591178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_DescribeRoute_591166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_DescribeRoute_591166; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_591181 = newJObject()
  add(path_591181, "routeName", newJString(routeName))
  add(path_591181, "meshName", newJString(meshName))
  add(path_591181, "virtualRouterName", newJString(virtualRouterName))
  result = call_591180.call(path_591181, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_591166(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_591167, base: "/", url: url_DescribeRoute_591168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_591200 = ref object of OpenApiRestCall_590364
proc url_DeleteRoute_591202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteRoute_591201(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete the route in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_591203 = path.getOrDefault("routeName")
  valid_591203 = validateParameter(valid_591203, JString, required = true,
                                 default = nil)
  if valid_591203 != nil:
    section.add "routeName", valid_591203
  var valid_591204 = path.getOrDefault("meshName")
  valid_591204 = validateParameter(valid_591204, JString, required = true,
                                 default = nil)
  if valid_591204 != nil:
    section.add "meshName", valid_591204
  var valid_591205 = path.getOrDefault("virtualRouterName")
  valid_591205 = validateParameter(valid_591205, JString, required = true,
                                 default = nil)
  if valid_591205 != nil:
    section.add "virtualRouterName", valid_591205
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
  var valid_591206 = header.getOrDefault("X-Amz-Signature")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Signature", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Content-Sha256", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Date")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Date", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Credential")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Credential", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Security-Token")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Security-Token", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Algorithm")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Algorithm", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-SignedHeaders", valid_591212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591213: Call_DeleteRoute_591200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_591213.validator(path, query, header, formData, body)
  let scheme = call_591213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591213.url(scheme.get, call_591213.host, call_591213.base,
                         call_591213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591213, url, valid)

proc call*(call_591214: Call_DeleteRoute_591200; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  var path_591215 = newJObject()
  add(path_591215, "routeName", newJString(routeName))
  add(path_591215, "meshName", newJString(meshName))
  add(path_591215, "virtualRouterName", newJString(virtualRouterName))
  result = call_591214.call(path_591215, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_591200(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_591201,
                                        base: "/", url: url_DeleteRoute_591202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_591231 = ref object of OpenApiRestCall_590364
proc url_UpdateVirtualNode_591233(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateVirtualNode_591232(path: JsonNode; query: JsonNode;
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
  var valid_591234 = path.getOrDefault("meshName")
  valid_591234 = validateParameter(valid_591234, JString, required = true,
                                 default = nil)
  if valid_591234 != nil:
    section.add "meshName", valid_591234
  var valid_591235 = path.getOrDefault("virtualNodeName")
  valid_591235 = validateParameter(valid_591235, JString, required = true,
                                 default = nil)
  if valid_591235 != nil:
    section.add "virtualNodeName", valid_591235
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
  var valid_591236 = header.getOrDefault("X-Amz-Signature")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-Signature", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-Content-Sha256", valid_591237
  var valid_591238 = header.getOrDefault("X-Amz-Date")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Date", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Credential")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Credential", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Security-Token")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Security-Token", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Algorithm")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Algorithm", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-SignedHeaders", valid_591242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591244: Call_UpdateVirtualNode_591231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_591244.validator(path, query, header, formData, body)
  let scheme = call_591244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591244.url(scheme.get, call_591244.host, call_591244.base,
                         call_591244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591244, url, valid)

proc call*(call_591245: Call_UpdateVirtualNode_591231; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_591246 = newJObject()
  var body_591247 = newJObject()
  add(path_591246, "meshName", newJString(meshName))
  if body != nil:
    body_591247 = body
  add(path_591246, "virtualNodeName", newJString(virtualNodeName))
  result = call_591245.call(path_591246, nil, nil, nil, body_591247)

var updateVirtualNode* = Call_UpdateVirtualNode_591231(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_591232, base: "/",
    url: url_UpdateVirtualNode_591233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_591216 = ref object of OpenApiRestCall_590364
proc url_DescribeVirtualNode_591218(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DescribeVirtualNode_591217(path: JsonNode; query: JsonNode;
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
  var valid_591219 = path.getOrDefault("meshName")
  valid_591219 = validateParameter(valid_591219, JString, required = true,
                                 default = nil)
  if valid_591219 != nil:
    section.add "meshName", valid_591219
  var valid_591220 = path.getOrDefault("virtualNodeName")
  valid_591220 = validateParameter(valid_591220, JString, required = true,
                                 default = nil)
  if valid_591220 != nil:
    section.add "virtualNodeName", valid_591220
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
  var valid_591221 = header.getOrDefault("X-Amz-Signature")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Signature", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Content-Sha256", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Date")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Date", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Credential")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Credential", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-Security-Token")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-Security-Token", valid_591225
  var valid_591226 = header.getOrDefault("X-Amz-Algorithm")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "X-Amz-Algorithm", valid_591226
  var valid_591227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-SignedHeaders", valid_591227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591228: Call_DescribeVirtualNode_591216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_591228.validator(path, query, header, formData, body)
  let scheme = call_591228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591228.url(scheme.get, call_591228.host, call_591228.base,
                         call_591228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591228, url, valid)

proc call*(call_591229: Call_DescribeVirtualNode_591216; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_591230 = newJObject()
  add(path_591230, "meshName", newJString(meshName))
  add(path_591230, "virtualNodeName", newJString(virtualNodeName))
  result = call_591229.call(path_591230, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_591216(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_591217, base: "/",
    url: url_DescribeVirtualNode_591218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_591248 = ref object of OpenApiRestCall_590364
proc url_DeleteVirtualNode_591250(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteVirtualNode_591249(path: JsonNode; query: JsonNode;
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
  var valid_591251 = path.getOrDefault("meshName")
  valid_591251 = validateParameter(valid_591251, JString, required = true,
                                 default = nil)
  if valid_591251 != nil:
    section.add "meshName", valid_591251
  var valid_591252 = path.getOrDefault("virtualNodeName")
  valid_591252 = validateParameter(valid_591252, JString, required = true,
                                 default = nil)
  if valid_591252 != nil:
    section.add "virtualNodeName", valid_591252
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
  var valid_591253 = header.getOrDefault("X-Amz-Signature")
  valid_591253 = validateParameter(valid_591253, JString, required = false,
                                 default = nil)
  if valid_591253 != nil:
    section.add "X-Amz-Signature", valid_591253
  var valid_591254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "X-Amz-Content-Sha256", valid_591254
  var valid_591255 = header.getOrDefault("X-Amz-Date")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Date", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-Credential")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Credential", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Security-Token")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Security-Token", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Algorithm")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Algorithm", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-SignedHeaders", valid_591259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591260: Call_DeleteVirtualNode_591248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_591260.validator(path, query, header, formData, body)
  let scheme = call_591260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591260.url(scheme.get, call_591260.host, call_591260.base,
                         call_591260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591260, url, valid)

proc call*(call_591261: Call_DeleteVirtualNode_591248; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_591262 = newJObject()
  add(path_591262, "meshName", newJString(meshName))
  add(path_591262, "virtualNodeName", newJString(virtualNodeName))
  result = call_591261.call(path_591262, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_591248(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_591249, base: "/",
    url: url_DeleteVirtualNode_591250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_591278 = ref object of OpenApiRestCall_590364
proc url_UpdateVirtualRouter_591280(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_591279(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_591281 = path.getOrDefault("meshName")
  valid_591281 = validateParameter(valid_591281, JString, required = true,
                                 default = nil)
  if valid_591281 != nil:
    section.add "meshName", valid_591281
  var valid_591282 = path.getOrDefault("virtualRouterName")
  valid_591282 = validateParameter(valid_591282, JString, required = true,
                                 default = nil)
  if valid_591282 != nil:
    section.add "virtualRouterName", valid_591282
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
  var valid_591283 = header.getOrDefault("X-Amz-Signature")
  valid_591283 = validateParameter(valid_591283, JString, required = false,
                                 default = nil)
  if valid_591283 != nil:
    section.add "X-Amz-Signature", valid_591283
  var valid_591284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591284 = validateParameter(valid_591284, JString, required = false,
                                 default = nil)
  if valid_591284 != nil:
    section.add "X-Amz-Content-Sha256", valid_591284
  var valid_591285 = header.getOrDefault("X-Amz-Date")
  valid_591285 = validateParameter(valid_591285, JString, required = false,
                                 default = nil)
  if valid_591285 != nil:
    section.add "X-Amz-Date", valid_591285
  var valid_591286 = header.getOrDefault("X-Amz-Credential")
  valid_591286 = validateParameter(valid_591286, JString, required = false,
                                 default = nil)
  if valid_591286 != nil:
    section.add "X-Amz-Credential", valid_591286
  var valid_591287 = header.getOrDefault("X-Amz-Security-Token")
  valid_591287 = validateParameter(valid_591287, JString, required = false,
                                 default = nil)
  if valid_591287 != nil:
    section.add "X-Amz-Security-Token", valid_591287
  var valid_591288 = header.getOrDefault("X-Amz-Algorithm")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Algorithm", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-SignedHeaders", valid_591289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591291: Call_UpdateVirtualRouter_591278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_591291.validator(path, query, header, formData, body)
  let scheme = call_591291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591291.url(scheme.get, call_591291.host, call_591291.base,
                         call_591291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591291, url, valid)

proc call*(call_591292: Call_UpdateVirtualRouter_591278; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_591293 = newJObject()
  var body_591294 = newJObject()
  add(path_591293, "meshName", newJString(meshName))
  if body != nil:
    body_591294 = body
  add(path_591293, "virtualRouterName", newJString(virtualRouterName))
  result = call_591292.call(path_591293, nil, nil, nil, body_591294)

var updateVirtualRouter* = Call_UpdateVirtualRouter_591278(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_591279, base: "/",
    url: url_UpdateVirtualRouter_591280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_591263 = ref object of OpenApiRestCall_590364
proc url_DescribeVirtualRouter_591265(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_591264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_591266 = path.getOrDefault("meshName")
  valid_591266 = validateParameter(valid_591266, JString, required = true,
                                 default = nil)
  if valid_591266 != nil:
    section.add "meshName", valid_591266
  var valid_591267 = path.getOrDefault("virtualRouterName")
  valid_591267 = validateParameter(valid_591267, JString, required = true,
                                 default = nil)
  if valid_591267 != nil:
    section.add "virtualRouterName", valid_591267
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
  var valid_591268 = header.getOrDefault("X-Amz-Signature")
  valid_591268 = validateParameter(valid_591268, JString, required = false,
                                 default = nil)
  if valid_591268 != nil:
    section.add "X-Amz-Signature", valid_591268
  var valid_591269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591269 = validateParameter(valid_591269, JString, required = false,
                                 default = nil)
  if valid_591269 != nil:
    section.add "X-Amz-Content-Sha256", valid_591269
  var valid_591270 = header.getOrDefault("X-Amz-Date")
  valid_591270 = validateParameter(valid_591270, JString, required = false,
                                 default = nil)
  if valid_591270 != nil:
    section.add "X-Amz-Date", valid_591270
  var valid_591271 = header.getOrDefault("X-Amz-Credential")
  valid_591271 = validateParameter(valid_591271, JString, required = false,
                                 default = nil)
  if valid_591271 != nil:
    section.add "X-Amz-Credential", valid_591271
  var valid_591272 = header.getOrDefault("X-Amz-Security-Token")
  valid_591272 = validateParameter(valid_591272, JString, required = false,
                                 default = nil)
  if valid_591272 != nil:
    section.add "X-Amz-Security-Token", valid_591272
  var valid_591273 = header.getOrDefault("X-Amz-Algorithm")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Algorithm", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-SignedHeaders", valid_591274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591275: Call_DescribeVirtualRouter_591263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_591275.validator(path, query, header, formData, body)
  let scheme = call_591275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591275.url(scheme.get, call_591275.host, call_591275.base,
                         call_591275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591275, url, valid)

proc call*(call_591276: Call_DescribeVirtualRouter_591263; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_591277 = newJObject()
  add(path_591277, "meshName", newJString(meshName))
  add(path_591277, "virtualRouterName", newJString(virtualRouterName))
  result = call_591276.call(path_591277, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_591263(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_591264, base: "/",
    url: url_DescribeVirtualRouter_591265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_591295 = ref object of OpenApiRestCall_590364
proc url_DeleteVirtualRouter_591297(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_591296(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_591298 = path.getOrDefault("meshName")
  valid_591298 = validateParameter(valid_591298, JString, required = true,
                                 default = nil)
  if valid_591298 != nil:
    section.add "meshName", valid_591298
  var valid_591299 = path.getOrDefault("virtualRouterName")
  valid_591299 = validateParameter(valid_591299, JString, required = true,
                                 default = nil)
  if valid_591299 != nil:
    section.add "virtualRouterName", valid_591299
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
  var valid_591300 = header.getOrDefault("X-Amz-Signature")
  valid_591300 = validateParameter(valid_591300, JString, required = false,
                                 default = nil)
  if valid_591300 != nil:
    section.add "X-Amz-Signature", valid_591300
  var valid_591301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591301 = validateParameter(valid_591301, JString, required = false,
                                 default = nil)
  if valid_591301 != nil:
    section.add "X-Amz-Content-Sha256", valid_591301
  var valid_591302 = header.getOrDefault("X-Amz-Date")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-Date", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Credential")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Credential", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Security-Token")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Security-Token", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Algorithm")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Algorithm", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-SignedHeaders", valid_591306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591307: Call_DeleteVirtualRouter_591295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_591307.validator(path, query, header, formData, body)
  let scheme = call_591307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591307.url(scheme.get, call_591307.host, call_591307.base,
                         call_591307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591307, url, valid)

proc call*(call_591308: Call_DeleteVirtualRouter_591295; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_591309 = newJObject()
  add(path_591309, "meshName", newJString(meshName))
  add(path_591309, "virtualRouterName", newJString(virtualRouterName))
  result = call_591308.call(path_591309, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_591295(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_591296, base: "/",
    url: url_DeleteVirtualRouter_591297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_591325 = ref object of OpenApiRestCall_590364
proc url_UpdateVirtualService_591327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateVirtualService_591326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_591328 = path.getOrDefault("virtualServiceName")
  valid_591328 = validateParameter(valid_591328, JString, required = true,
                                 default = nil)
  if valid_591328 != nil:
    section.add "virtualServiceName", valid_591328
  var valid_591329 = path.getOrDefault("meshName")
  valid_591329 = validateParameter(valid_591329, JString, required = true,
                                 default = nil)
  if valid_591329 != nil:
    section.add "meshName", valid_591329
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
  var valid_591330 = header.getOrDefault("X-Amz-Signature")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-Signature", valid_591330
  var valid_591331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591331 = validateParameter(valid_591331, JString, required = false,
                                 default = nil)
  if valid_591331 != nil:
    section.add "X-Amz-Content-Sha256", valid_591331
  var valid_591332 = header.getOrDefault("X-Amz-Date")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-Date", valid_591332
  var valid_591333 = header.getOrDefault("X-Amz-Credential")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Credential", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Security-Token")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Security-Token", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Algorithm")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Algorithm", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-SignedHeaders", valid_591336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591338: Call_UpdateVirtualService_591325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_591338.validator(path, query, header, formData, body)
  let scheme = call_591338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591338.url(scheme.get, call_591338.host, call_591338.base,
                         call_591338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591338, url, valid)

proc call*(call_591339: Call_UpdateVirtualService_591325;
          virtualServiceName: string; meshName: string; body: JsonNode): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  var path_591340 = newJObject()
  var body_591341 = newJObject()
  add(path_591340, "virtualServiceName", newJString(virtualServiceName))
  add(path_591340, "meshName", newJString(meshName))
  if body != nil:
    body_591341 = body
  result = call_591339.call(path_591340, nil, nil, nil, body_591341)

var updateVirtualService* = Call_UpdateVirtualService_591325(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_591326, base: "/",
    url: url_UpdateVirtualService_591327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_591310 = ref object of OpenApiRestCall_590364
proc url_DescribeVirtualService_591312(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DescribeVirtualService_591311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_591313 = path.getOrDefault("virtualServiceName")
  valid_591313 = validateParameter(valid_591313, JString, required = true,
                                 default = nil)
  if valid_591313 != nil:
    section.add "virtualServiceName", valid_591313
  var valid_591314 = path.getOrDefault("meshName")
  valid_591314 = validateParameter(valid_591314, JString, required = true,
                                 default = nil)
  if valid_591314 != nil:
    section.add "meshName", valid_591314
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
  var valid_591315 = header.getOrDefault("X-Amz-Signature")
  valid_591315 = validateParameter(valid_591315, JString, required = false,
                                 default = nil)
  if valid_591315 != nil:
    section.add "X-Amz-Signature", valid_591315
  var valid_591316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591316 = validateParameter(valid_591316, JString, required = false,
                                 default = nil)
  if valid_591316 != nil:
    section.add "X-Amz-Content-Sha256", valid_591316
  var valid_591317 = header.getOrDefault("X-Amz-Date")
  valid_591317 = validateParameter(valid_591317, JString, required = false,
                                 default = nil)
  if valid_591317 != nil:
    section.add "X-Amz-Date", valid_591317
  var valid_591318 = header.getOrDefault("X-Amz-Credential")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "X-Amz-Credential", valid_591318
  var valid_591319 = header.getOrDefault("X-Amz-Security-Token")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "X-Amz-Security-Token", valid_591319
  var valid_591320 = header.getOrDefault("X-Amz-Algorithm")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Algorithm", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-SignedHeaders", valid_591321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591322: Call_DescribeVirtualService_591310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_591322.validator(path, query, header, formData, body)
  let scheme = call_591322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591322.url(scheme.get, call_591322.host, call_591322.base,
                         call_591322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591322, url, valid)

proc call*(call_591323: Call_DescribeVirtualService_591310;
          virtualServiceName: string; meshName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  var path_591324 = newJObject()
  add(path_591324, "virtualServiceName", newJString(virtualServiceName))
  add(path_591324, "meshName", newJString(meshName))
  result = call_591323.call(path_591324, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_591310(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_591311, base: "/",
    url: url_DescribeVirtualService_591312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_591342 = ref object of OpenApiRestCall_590364
proc url_DeleteVirtualService_591344(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteVirtualService_591343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual service in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_591345 = path.getOrDefault("virtualServiceName")
  valid_591345 = validateParameter(valid_591345, JString, required = true,
                                 default = nil)
  if valid_591345 != nil:
    section.add "virtualServiceName", valid_591345
  var valid_591346 = path.getOrDefault("meshName")
  valid_591346 = validateParameter(valid_591346, JString, required = true,
                                 default = nil)
  if valid_591346 != nil:
    section.add "meshName", valid_591346
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
  var valid_591347 = header.getOrDefault("X-Amz-Signature")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Signature", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Content-Sha256", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Date")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Date", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Credential")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Credential", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Security-Token")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Security-Token", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Algorithm")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Algorithm", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-SignedHeaders", valid_591353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591354: Call_DeleteVirtualService_591342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_591354.validator(path, query, header, formData, body)
  let scheme = call_591354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591354.url(scheme.get, call_591354.host, call_591354.base,
                         call_591354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591354, url, valid)

proc call*(call_591355: Call_DeleteVirtualService_591342;
          virtualServiceName: string; meshName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  var path_591356 = newJObject()
  add(path_591356, "virtualServiceName", newJString(virtualServiceName))
  add(path_591356, "meshName", newJString(meshName))
  result = call_591355.call(path_591356, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_591342(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_591343, base: "/",
    url: url_DeleteVirtualService_591344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591357 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591359(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591358(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an App Mesh resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
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
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  section = newJObject()
  var valid_591360 = query.getOrDefault("nextToken")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "nextToken", valid_591360
  var valid_591361 = query.getOrDefault("limit")
  valid_591361 = validateParameter(valid_591361, JInt, required = false, default = nil)
  if valid_591361 != nil:
    section.add "limit", valid_591361
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_591362 = query.getOrDefault("resourceArn")
  valid_591362 = validateParameter(valid_591362, JString, required = true,
                                 default = nil)
  if valid_591362 != nil:
    section.add "resourceArn", valid_591362
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
  var valid_591363 = header.getOrDefault("X-Amz-Signature")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-Signature", valid_591363
  var valid_591364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Content-Sha256", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-Date")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-Date", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Credential")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Credential", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Security-Token")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Security-Token", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Algorithm")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Algorithm", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-SignedHeaders", valid_591369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591370: Call_ListTagsForResource_591357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_591370.validator(path, query, header, formData, body)
  let scheme = call_591370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591370.url(scheme.get, call_591370.host, call_591370.base,
                         call_591370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591370, url, valid)

proc call*(call_591371: Call_ListTagsForResource_591357; resourceArn: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listTagsForResource
  ## List the tags for an App Mesh resource.
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
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  var query_591372 = newJObject()
  add(query_591372, "nextToken", newJString(nextToken))
  add(query_591372, "limit", newJInt(limit))
  add(query_591372, "resourceArn", newJString(resourceArn))
  result = call_591371.call(nil, query_591372, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591357(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_591358, base: "/",
    url: url_ListTagsForResource_591359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591373 = ref object of OpenApiRestCall_590364
proc url_TagResource_591375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591376 = query.getOrDefault("resourceArn")
  valid_591376 = validateParameter(valid_591376, JString, required = true,
                                 default = nil)
  if valid_591376 != nil:
    section.add "resourceArn", valid_591376
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
  var valid_591377 = header.getOrDefault("X-Amz-Signature")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Signature", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-Content-Sha256", valid_591378
  var valid_591379 = header.getOrDefault("X-Amz-Date")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-Date", valid_591379
  var valid_591380 = header.getOrDefault("X-Amz-Credential")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = nil)
  if valid_591380 != nil:
    section.add "X-Amz-Credential", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Security-Token")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Security-Token", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Algorithm")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Algorithm", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-SignedHeaders", valid_591383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591385: Call_TagResource_591373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_591385.validator(path, query, header, formData, body)
  let scheme = call_591385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591385.url(scheme.get, call_591385.host, call_591385.base,
                         call_591385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591385, url, valid)

proc call*(call_591386: Call_TagResource_591373; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  var query_591387 = newJObject()
  var body_591388 = newJObject()
  if body != nil:
    body_591388 = body
  add(query_591387, "resourceArn", newJString(resourceArn))
  result = call_591386.call(nil, query_591387, nil, nil, body_591388)

var tagResource* = Call_TagResource_591373(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_591374,
                                        base: "/", url: url_TagResource_591375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591389 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591391(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591392 = query.getOrDefault("resourceArn")
  valid_591392 = validateParameter(valid_591392, JString, required = true,
                                 default = nil)
  if valid_591392 != nil:
    section.add "resourceArn", valid_591392
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
  var valid_591393 = header.getOrDefault("X-Amz-Signature")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-Signature", valid_591393
  var valid_591394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591394 = validateParameter(valid_591394, JString, required = false,
                                 default = nil)
  if valid_591394 != nil:
    section.add "X-Amz-Content-Sha256", valid_591394
  var valid_591395 = header.getOrDefault("X-Amz-Date")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-Date", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Credential")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Credential", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Security-Token")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Security-Token", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Algorithm")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Algorithm", valid_591398
  var valid_591399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-SignedHeaders", valid_591399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591401: Call_UntagResource_591389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_591401.validator(path, query, header, formData, body)
  let scheme = call_591401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591401.url(scheme.get, call_591401.host, call_591401.base,
                         call_591401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591401, url, valid)

proc call*(call_591402: Call_UntagResource_591389; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  var query_591403 = newJObject()
  var body_591404 = newJObject()
  if body != nil:
    body_591404 = body
  add(query_591403, "resourceArn", newJString(resourceArn))
  result = call_591402.call(nil, query_591403, nil, nil, body_591404)

var untagResource* = Call_UntagResource_591389(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_591390,
    base: "/", url: url_UntagResource_591391, schemes: {Scheme.Https, Scheme.Http})
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
